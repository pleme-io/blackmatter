# Blizzard Preset - Full desktop using new modular system
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.blizzard-preset;
in {
  options.blackmatter.profiles.presets.blizzard-preset = {
    enable = mkEnableOption "Blizzard preset (full desktop with Hyprland)";
  };

  config = mkIf cfg.enable {
    # Use base desktop profile (includes all package sets)
    blackmatter.profiles.base.desktop.enable = true;

    # Use Hyprland variant
    blackmatter.profiles.variants.hyprland.enable = true;
    blackmatter.profiles.variants.hyprland.enableNetworkManager = false; # blizzard doesn't use nm-applet

    # No specific theme (uses default)
  };
}
