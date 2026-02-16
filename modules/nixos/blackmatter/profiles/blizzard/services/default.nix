# modules/nixos/blackmatter/profiles/blizzard/services/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.services;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.services = {
    envfs = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable envfs for /usr/bin/env compatibility";
      };
    };

    steam = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Steam gaming platform";
      };

      remotePlay = {
        openFirewall = mkOption {
          type = types.bool;
          default = false;
          description = "Open firewall for Steam Remote Play";
        };
      };

      hardware = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Steam hardware support (controllers, VR)";
        };
      };
    };
  };

  config = mkIf profileCfg.enable {
    services.envfs.enable = cfg.envfs.enable;

    programs.steam = mkIf cfg.steam.enable {
      enable = true;
      remotePlay.openFirewall = cfg.steam.remotePlay.openFirewall;
    };

    hardware.steam-hardware.enable = cfg.steam.hardware.enable;
  };
}
