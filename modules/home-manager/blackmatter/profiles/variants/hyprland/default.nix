# Hyprland Desktop Variant
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.variants.hyprland;
in {
  options.blackmatter.profiles.variants.hyprland = {
    enable = mkEnableOption "Hyprland desktop environment variant";
    enableNetworkManager = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable NetworkManager applet and autostart";
    };
  };

  config = mkIf cfg.enable {
    # Enable Hyprland
    blackmatter.components.desktop.hyprland.enable = true;

    # Enable Wayland compositors
    blackmatter.components.desktop.compositors = {
      waybar.enable = true;
      mako.enable = true;
      fuzzel.enable = true;
      swaylock.enable = true;
      swayidle.enable = true;
    };

    # Wayland utilities
    home.packages = with pkgs; ([
      wl-clipboard
      wtype
      wev
    ] ++ lib.optionals cfg.enableNetworkManager [
      networkmanagerapplet  # nm-applet for wifi management
    ]);

    # Override hyprland autostart
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
      ${lib.optionalString cfg.enableNetworkManager "exec-once = nm-applet --indicator"}
      exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1

      # end autostart these programs
    '';
  };
}
