# modules/nixos/blackmatter/profiles/nordstorm/xserver/default.nix
# X11 and Wayland configuration for GNOME
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      xkb = {
        options = "caps:escape";
        layout = "us";
        variant = "";
      };
      autoRepeatDelay = 135;
      autoRepeatInterval = 40;
      # GNOME doesn't need explicit videoDrivers usually, but keep nvidia if needed
      # videoDrivers = ["nvidia"];
    };

    # GDM display manager (nixos-24.11 path)
    services.xserver.displayManager.gdm = {
      enable = true;
      wayland = true;
    };

    # GNOME desktop manager (nixos-24.11 path)
    services.xserver.desktopManager.gnome.enable = true;
  };
}
