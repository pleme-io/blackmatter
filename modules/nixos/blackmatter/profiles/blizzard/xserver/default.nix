# modules/nixos/blackmatter/profiles/blizzard/xserver/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.xserver;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.xserver = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable X11 server";
    };
  };

  config = mkIf (profileCfg.enable && cfg.enable) {
    services.xserver = {
      enable = true;
      xkb = {
        options = "caps:escape";
        layout = "us";
        variant = "";
      };
      autoRepeatDelay = 135;
      autoRepeatInterval = 40;
      videoDrivers = ["nvidia"];
      windowManager = {
        leftwm = {enable = false;};
        i3 = {
          enable = true;
          extraPackages = with pkgs; [
            i3blocks
            i3status
            i3lock
            dmenu
          ];
        };
      };
    };

    # Use nixos-24.11 paths
    services.xserver.displayManager.gdm = {
      enable = false;
      wayland = false;
    };

    services.xserver.desktopManager.gnome.enable = false;
  };
}
