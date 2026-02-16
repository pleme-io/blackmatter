# Cosmic Desktop Variant
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.variants.cosmic;
in {
  options.blackmatter.profiles.variants.cosmic = {
    enable = mkEnableOption "Cosmic desktop environment variant";
    enableCompositors = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Wayland compositors (waybar, mako, etc)";
    };
    enableNetworkManager = mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NetworkManager applet";
    };
  };

  config = mkIf cfg.enable {
    # Enable Cosmic
    blackmatter.components.desktop.cosmic.enable = true;

    # Cosmic uses its own compositor, but we can still enable some tools
    blackmatter.components.desktop.compositors = mkIf cfg.enableCompositors {
      mako.enable = true;
      swaylock.enable = true;
      swayidle.enable = true;
    };

    # Wayland utilities
    home.packages = with pkgs; ([
      wl-clipboard
      wtype
      wev
    ] ++ lib.optionals cfg.enableNetworkManager [
      networkmanagerapplet
    ]);
  };
}
