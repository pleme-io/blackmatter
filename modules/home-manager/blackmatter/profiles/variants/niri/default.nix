# Niri Desktop Variant
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.variants.niri;
in {
  options.blackmatter.profiles.variants.niri = {
    enable = mkEnableOption "Niri desktop environment variant";
    enableNetworkManager = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable NetworkManager applet";
    };
  };

  config = mkIf cfg.enable {
    # Enable Niri
    blackmatter.components.desktop.niri.enable = true;

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
      networkmanagerapplet
    ]);
  };
}
