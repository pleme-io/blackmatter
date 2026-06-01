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

  # Post-build hook: a thin env+exec wrapper around the unified Rust binary
  # (dev-tools/nix-hooks → `nix-post-build-hook`), supplied by the consumer
  # via `nix.performance.atticCache.hookPackage`. The binary owns codesign +
  # attic push with a SESSION-CACHED login (no per-derivation
  # "✍️ Overwriting server 'nexus'" noise), a single batched
  # `attic push --jobs`, and CAPTURED subprocess output (so it never
  # corrupts the daemon's internal-JSON log stream → no more "bad JSON log
  # message from the derivation builder" spam). This replaces the old inline
  # `attic login`/`push` shell hook entirely — there is no shell
  # implementation of the push logic anymore. When no `hookPackage` is
  # provided the module emits NO post-build-hook; the consumer wires its own
  # (e.g. a platform-specific typed owner module).
  hookWrapper = pkgs.writeShellScript "nix-post-build-hook" ''
    export NIX_HOOK_CODESIGN="${if pkgs.stdenv.hostPlatform.isDarwin then "1" else "0"}"
    export ATTIC_CACHE="${cfg.atticCache.cacheName}"
    export ATTIC_SERVER="${cfg.atticCache.url}"
    ${optionalString (cfg.atticCache.tokenFile != null) ''
    export ATTIC_TOKEN_FILE="${cfg.atticCache.tokenFile}"
    ''}
    ${optionalString (cfg.atticCache.authToken != null) ''
    export ATTIC_TOKEN="${cfg.atticCache.authToken}"
    ''}
    export PATH="${pkgs.attic-client}/bin:${pkgs.curl}/bin:${pkgs.coreutils}/bin:/usr/bin:$PATH"
    exec ${cfg.atticCache.hookPackage}/bin/nix-post-build-hook
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

        hookPackage = mkOption {
          type = types.nullOr types.package;
          default = null;
          description = ''
            Package providing the unified `nix-post-build-hook` Rust binary
            (dev-tools/nix-hooks). When set AND `enablePush` is true, the
            module emits a thin env+exec post-build-hook wrapping it. When
            null (the default) NO post-build-hook is emitted — the inline
            shell implementation was removed, so a consumer that wants the
            push hook must supply this package (or wire its own typed owner
            module). This keeps the generic module free of any shell
            attic-push logic.
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
        # Priority: mkOptionDefault (1500) — weakest baseline, so profile-level
        # opinions (e.g. profiles/darwin/developer-resources in the nix repo)
        # using mkDefault (1000) win without needing mkForce on either side.
        keep-derivations = mkOptionDefault (!pkgs.stdenv.isDarwin);
        keep-outputs = mkOptionDefault (!pkgs.stdenv.isDarwin);
        builders-use-substitutes = true;

        # Trust settings
        trusted-users = ["root" "@wheel" "@admin"] ++ cfg.trustedUsers;

        # Sandbox: relaxed = sandbox by default, but permit __noChroot
        # opt-outs for trusted users. Required for gen-IFD's
        # mk-build-spec.nix runCommand which sets __noChroot=true so
        # `cargo metadata` can reach the crates.io registry index.
        # The hermetic gen-cargo rewrite (#13) retires the need; until
        # then, relaxed is the fleet-wide default. Per the GEN
        # TYPED-SPEC CONTRACT — regeneration is background to rebuild;
        # this is the sandbox setting that makes it run.
        sandbox = mkDefault "relaxed";

        # Extra sandbox-paths required by FODs that resolve DNS inside
        # the sandbox (fetchgit, fetchurl, nix-prefetch-git). Without
        # /etc/resolv.conf, libc's resolver has no nameserver list and
        # git clone fails with "Could not resolve host: github.com" —
        # observed on rio (dnsmasq-mediated resolv.conf on the host).
        #
        # ONLY include real files here: NixOS-style symlinks (e.g.
        # /etc/hosts -> /etc/static/hosts -> /nix/store/...) fail to
        # bind-mount with "filesystem error: cannot copy: Invalid
        # argument" — nix's sandbox-paths copy doesn't traverse the
        # multi-level symlink chain. /etc/resolv.conf is the only
        # canonical real-file DNS resolver hook; libc finds protocols/
        # services/hosts via static glibc fallbacks when those entries
        # are missing.
        extra-sandbox-paths = lib.mkDefault [
          "/etc/resolv.conf"
        ];

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

        # Automatic push to Attic cache after successful builds — only when
        # the consumer supplies the Rust hook binary (hookPackage). No
        # hookPackage ⇒ no hook emitted here; the shell implementation is
        # gone for good.
        ${optionalString (cfg.atticCache.enable && cfg.atticCache.enablePush && cfg.atticCache.hookPackage != null) ''
        post-build-hook = ${hookWrapper}
        ''}
      '';
    };
  };
}
