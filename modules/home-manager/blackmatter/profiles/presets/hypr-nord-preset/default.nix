# Hypr-Nord Preset - Nord-themed Hyprland desktop with nm-applet
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.hypr-nord-preset;
in {
  options.blackmatter.profiles.presets.hypr-nord-preset = {
    enable = mkEnableOption "Hypr-Nord preset (Hyprland with Nord theme and nm-applet)";
  };

  config = mkIf cfg.enable {
    # Use base desktop profile (includes all package sets)
    blackmatter.profiles.base.desktop.enable = true;

    # Use Hyprland variant with nm-applet
    blackmatter.profiles.variants.hyprland.enable = true;
    blackmatter.profiles.variants.hyprland.enableNetworkManager = true;

    # Use Nord theme
    blackmatter.themes.nord.enable = true;
    blackmatter.themes.nord.gtk.enable = true;
    blackmatter.themes.nord.qt.enable = true;

    # Override hyprland autostart to include nm-applet
    home.file.".config/hypr/autostart.conf".text = ''
      ################################################################################
      # autostart these programs
      ################################################################################

      exec-once = udiskie
      exec-once = hyprpaper
      exec-once = $bar
      exec-once = hyprcursor init
      exec-once = hypridle
      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = nm-applet --indicator
      exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1

      # end autostart these programs
    '';
  };
}
