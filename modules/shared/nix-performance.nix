# modules/shared/nix-performance.nix
# Shared Nix performance configuration for both NixOS and Darwin
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.nix.performance;

  # Post-build hook to push to Attic cache.
  # Uses full store path for attic-client (nix daemon has minimal PATH).
  # Reads token from file on disk (written by sops-nix) rather than env var
  # (daemon environment doesn't inherit user session variables).
  attic = "${pkgs.attic-client}/bin/attic";
  atticPushHook = pkgs.writeShellScript "attic-push-hook" ''
    set -eu
    set -f # disable globbing
    export IFS=' '

    # Read token from file or inline value
    ${if cfg.atticCache.tokenFile != null then ''
    if [ -r "${cfg.atticCache.tokenFile}" ]; then
      ATTIC_TOKEN="$(cat "${cfg.atticCache.tokenFile}")"
      export ATTIC_TOKEN
    fi
    '' else if cfg.atticCache.authToken != null then ''
    export ATTIC_TOKEN="${cfg.atticCache.authToken}"
    '' else ''
    # No tokenFile or authToken configured — fall back to ATTIC_TOKEN env var
    ''}
    if [ -z "''${ATTIC_TOKEN:-}" ]; then
      echo "Attic: no token available, skipping cache push" >&2
      exit 0
    fi

    # Login to cache (creates/updates config)
    if ! ${attic} login nexus "${cfg.atticCache.url}" "$ATTIC_TOKEN" 2>&1; then
      echo "Attic: login failed, skipping cache push" >&2
      exit 0
    fi

    # Push each built path to the cache
    for path in $OUT_PATHS; do
      ${attic} push "${cfg.atticCache.cacheName}" "$path" 2>/dev/null || true
    done
  '';
in {
  options = {
    nix.performance = {
      enable = mkEnableOption "high-performance Nix configuration";

      atticCache = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Attic binary cache";
        };

        url = mkOption {
          type = types.str;
          default = "https://cache.nixos.org";
          description = "Attic cache URL";
        };

        publicKeys = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Attic cache public keys (all keys that might sign cache items)";
        };

        authToken = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Attic cache JWT authentication token (baked into hook script).
            Prefer tokenFile over this — avoids leaking the token into the nix store.
          '';
        };

        tokenFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Path to a file containing the Attic cache JWT token.
            Read at runtime by the post-build-hook (nix daemon runs as root,
            can read user-owned 0600 files). Written by sops-nix on activation.
          '';
        };

        enablePush = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable automatic push to Attic cache after successful builds.
            Set tokenFile to the sops-managed token path for authentication.
          '';
        };

        cacheName = mkOption {
          type = types.str;
          default = "default";
          description = "Attic cache name to push to";
        };

        netrcFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            Path to a netrc file containing credentials for Attic cache and
            private GitHub repos. Read by the nix daemon at runtime — root can
            read user-owned 0600 files. Enables both binary cache auth and
            github: flake input fetching for private repos.
          '';
        };
      };

      gcSettings = {
        automatic = mkOption {
          type = types.bool;
          default = true;
          description = "Enable automatic garbage collection";
        };

        interval = mkOption {
          type = types.attrs;
          default = { Hour = 12; Minute = 0; };
          description = "Garbage collection interval (LaunchDaemon format for Darwin). Default is noon when laptops are likely awake.";
        };

        options = mkOption {
          type = types.str;
          default = "--delete-older-than 3d";
          description = "Garbage collection options";
        };
      };

      extraSubstituters = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional substituters beyond Attic and nixos.org";
        example = ["https://hyprland.cachix.org"];
      };

      extraPublicKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional public keys for substituters";
        example = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      };

      trustedUsers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Additional trusted users beyond the defaults (root, @wheel, @admin).
          Trusted users can configure binary caches and other settings.
        '';
        example = ["alice" "bob"];
      };

      acceptFlakeConfig = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to accept flake configuration from flake.nix files.
          This allows flakes to set their own substituters and other settings.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    nix = {
      # Garbage collection
      gc = mkIf cfg.gcSettings.automatic {
        automatic = true;
        # NixOS uses 'dates' (systemd timer format), Darwin uses 'interval' (LaunchDaemon format)
        ${if pkgs.stdenv.isDarwin then "interval" else "dates"} =
          if pkgs.stdenv.isDarwin
          then cfg.gcSettings.interval
          else "03:00";  # 3 AM daily for NixOS
        options = cfg.gcSettings.options;
      };

      # Core settings for optimal performance
      settings = {
        # Enable flakes and nix-command
        experimental-features = ["nix-command" "flakes"];

        # Performance: Use all available resources
        max-jobs = mkDefault "auto";
        cores = mkDefault 0; # Use all cores

        # Build optimization
        # On Darwin (dev laptops), disable keep-derivations/keep-outputs so GC can
        # reclaim build intermediates. Attic cache makes local retention redundant.
        # On NixOS (servers), keep them for faster rebuilds without cache roundtrips.
        keep-derivations = mkDefault (!pkgs.stdenv.isDarwin);
        keep-outputs = mkDefault (!pkgs.stdenv.isDarwin);
        builders-use-substitutes = true;

        # Trust settings
        trusted-users = ["root" "@wheel" "@admin"] ++ cfg.trustedUsers;

        # Accept flake configuration
        accept-flake-config = cfg.acceptFlakeConfig;

        # Binary caches (prioritized order)
        substituters = mkMerge [
          (mkIf cfg.atticCache.enable [cfg.atticCache.url])
          ["https://cache.nixos.org"]
          cfg.extraSubstituters
        ];

        trusted-public-keys = mkMerge [
          (mkIf cfg.atticCache.enable cfg.atticCache.publicKeys)
          ["cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="]
          cfg.extraPublicKeys
        ];
      };

      # Auto-optimize store
      optimise.automatic = true;

      # Extra options for memory management
      extraOptions = ''
        # Disk space management
        min-free = ${toString (1024 * 1024 * 1024)}
        max-free = ${toString (4096 * 1024 * 1024)}

        # Connection settings for better reliability
        connect-timeout = 5

        # Download settings
        download-attempts = 3
        fallback = true
        download-buffer-size = 268435456

        # netrc-file: used by daemon for Attic substituter auth + github: private repo fetching.
        # Points to the SOPS-managed user netrc (root can read 0600 files).
        ${optionalString (cfg.atticCache.netrcFile != null) ''
        netrc-file = ${cfg.atticCache.netrcFile}
        ''}

        # Automatic push to Attic cache after successful builds
        ${optionalString (cfg.atticCache.enable && cfg.atticCache.enablePush) ''
        post-build-hook = ${atticPushHook}
        ''}
      '';
    };
  };
}
