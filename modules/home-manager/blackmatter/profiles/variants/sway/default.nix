# Sway Variant - i3-compatible Wayland compositor
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.variants.sway;
in {
  options.blackmatter.profiles.variants.sway = {
    enable = mkEnableOption "Sway variant (i3-compatible Wayland compositor)";

    enableCompositors = mkOption {
      type = types.bool;
      default = true;
      description = "Enable compositor components (waybar, mako, fuzzel, swaylock, swayidle)";
    };

    enableNetworkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NetworkManager applet";
    };
  };

  config = mkIf cfg.enable {
    # Enable Sway component
    blackmatter.components.desktop.sway.enable = true;

    # Enable compositor components
    blackmatter.components.desktop.compositors = mkIf cfg.enableCompositors {
      waybar.enable = true;
      mako.enable = true;
      fuzzel.enable = true;
      swaylock.enable = true;
      swayidle.enable = true;
    };

    # Wayland utilities
    home.packages = with pkgs;
      [
        wl-clipboard
        wtype
        wev
        swaybg # Sway-specific background setter
      ]
      ++ optionals cfg.enableNetworkManager [networkmanagerapplet];
  };
}
