# modules/nixos/blackmatter/profiles/blizzard/nix/default.nix
# Nix settings wrapper for nix-performance.nix module
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.nix;
  profileCfg = config.blackmatter.profiles.blizzard;
  atticConfig = import ../../../../../../lib/attic-config.nix;
in {
  options.blackmatter.profiles.blizzard.nix = {
    performance = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable high-performance Nix configuration";
      };

      trustedUsers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional trusted users beyond root, @wheel, @admin";
        example = ["alice" "bob"];
      };

      acceptFlakeConfig = mkOption {
        type = types.bool;
        default = true;
        description = "Accept flake configuration from flake.nix files";
      };

      atticCache = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Attic binary cache";
        };

        enablePush = mkOption {
          type = types.bool;
          default = false;
          description = "Automatically push builds to Attic cache";
        };

        cacheName = mkOption {
          type = types.str;
          default = atticConfig.cache.cacheName;
          description = "Attic cache name to push to";
        };
      };

      extraSubstituters = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional binary cache substituters";
        example = ["https://example.cachix.org"];
      };

      extraPublicKeys = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional public keys for substituters";
      };
    };
  };

  config = mkIf profileCfg.enable {
    # Delegate to nix-performance module
    nix.performance = {
      enable = cfg.performance.enable;
      trustedUsers = cfg.performance.trustedUsers;
      acceptFlakeConfig = cfg.performance.acceptFlakeConfig;

      atticCache = {
        enable = cfg.performance.atticCache.enable;
        enablePush = cfg.performance.atticCache.enablePush;
        cacheName = cfg.performance.atticCache.cacheName;
      };

      # Add Hyprland cachix + any user-defined substituters
      extraSubstituters = ["https://hyprland.cachix.org"] ++ cfg.performance.extraSubstituters;
      extraPublicKeys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="] ++ cfg.performance.extraPublicKeys;
    };
  };
}
