# Cosmic-Nord Preset - Nord-themed COSMIC desktop
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.cosmic-nord-preset;
in {
  options.blackmatter.profiles.presets.cosmic-nord-preset = {
    enable = mkEnableOption "Cosmic-Nord preset (COSMIC desktop with Nord theme guide)";
  };

  config = mkIf cfg.enable {
    # Use base desktop profile (includes all package sets)
    blackmatter.profiles.base.desktop.enable = true;

    # Use Cosmic variant (compositors disabled - COSMIC has its own)
    blackmatter.profiles.variants.cosmic.enable = true;
    blackmatter.profiles.variants.cosmic.enableCompositors = false;
    blackmatter.profiles.variants.cosmic.enableNetworkManager = true;

    # Use Nord theme for GTK apps
    blackmatter.themes.nord.enable = true;
    blackmatter.themes.nord.gtk.enable = true;
    blackmatter.themes.nord.qt.enable = true;

    # COSMIC configuration is done through COSMIC Settings
    # Create a README with Nord color values for manual theming
    home.file.".config/cosmic/nord-theme.md".text = ''
      # COSMIC Nord Theme Configuration

      To apply Nord theme to COSMIC:
      1. Open COSMIC Settings
      2. Go to Appearance
      3. Create custom theme with these Nord colors:

      ## Polar Night (Backgrounds)
      - nord0: #2e3440 - Base background
      - nord1: #3b4252 - Elevated elements
      - nord2: #434c5e - Active selections
      - nord3: #4c566a - Comments

      ## Snow Storm (Foregrounds)
      - nord4: #d8dee9 - Text
      - nord5: #e5e9f0 - Subtle text
      - nord6: #eceff4 - Brightest text

      ## Frost (Accents)
      - nord7: #8fbcbb - Teal
      - nord8: #88c0d0 - Cyan (primary accent)
      - nord9: #81a1c1 - Light blue
      - nord10: #5e81ac - Dark blue

      ## Aurora (Semantic)
      - nord11: #bf616a - Red (errors)
      - nord12: #d08770 - Orange
      - nord13: #ebcb8b - Yellow (warnings)
      - nord14: #a3be8c - Green (success)
      - nord15: #b48ead - Purple

      ## Quick Setup
      Background: nord0 (#2e3440)
      Primary Accent: nord8 (#88c0d0)
      Success: nord14 (#a3be8c)
      Warning: nord13 (#ebcb8b)
      Error: nord11 (#bf616a)
    '';

    # Enable gnome-keyring for password management
    services.gnome-keyring.enable = true;
  };
}
