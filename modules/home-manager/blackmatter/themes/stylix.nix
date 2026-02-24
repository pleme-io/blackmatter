# themes/stylix.nix — central Nord/Stylix color hub
#
# Single module that owns all Stylix configuration. All other blackmatter
# components read colors from config.lib.stylix.colors; nothing else touches
# stylix.* options.
#
# Requires inputs.stylix.homeManagerModules.stylix in sharedModules.
#
# base16 -> Nord mapping:
#   base00 = #2E3440  (nord0  — bg darkest / polar night 0)
#   base01 = #3B4252  (nord1  — selection / polar night 1)
#   base02 = #434C5E  (nord2  — highlight / polar night 2)
#   base03 = #4C566A  (nord3  — comments / polar night 3)
#   base04 = #D8DEE9  (nord4  — fg subtle / snow storm 0)
#   base05 = #E5E9F0  (nord5  — fg / snow storm 1)
#   base06 = #ECEFF4  (nord6  — fg bright / snow storm 2)
#   base07 = #8FBCBB  (nord7  — frost teal)
#   base08 = #BF616A  (nord11 — red / aurora red)
#   base09 = #D08770  (nord12 — orange / aurora orange)
#   base0A = #EBCB8B  (nord13 — yellow / aurora yellow)
#   base0B = #A3BE8C  (nord14 — green / aurora green)
#   base0C = #88C0D0  (nord8  — frost cyan — primary accent)
#   base0D = #81A1C1  (nord9  — frost blue)
#   base0E = #B48EAD  (nord15 — purple / aurora purple)
#   base0F = #5E81AC  (nord10 — frost dark)
#
# Blackmatter-owned targets (Stylix target disabled here):
#   ghostty  — blackmatter owns detailed Nord palette + macOS config file
#   neovim   — blackmatter owns nord.nvim plugin + custom highlights
#   starship — blackmatter owns custom snowflake format (static config file)
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.blackmatter.themes.nord;
in {
  # When Nord is disabled, explicitly turn Stylix off so its mandatory
  # assertions (base16Scheme/image required) don't fire on non-Nord profiles.
  config = mkMerge [
    (mkIf (!cfg.enable) { stylix.enable = false; })

    (mkIf cfg.enable { stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

      # Wallpaper is required by Stylix. On Darwin it doesn't affect the desktop
      # (macOS manages its own wallpaper), but the option must be set.
      # A 1x1 solid Nord polar-night pixel serves as a neutral placeholder.
      image = pkgs.runCommand "nord-wallpaper.png" {
        nativeBuildInputs = [ pkgs.imagemagick ];
      } ''
        convert -size 1x1 xc:#2E3440 $out
      '';

      fonts = {
        monospace = {
          package = pkgs.jetbrains-mono;
          name = "JetBrains Mono";
        };
        sansSerif = {
          package = pkgs.inter;
          name = "Inter";
        };
        sizes.terminal = 13;
        sizes.applications = 12;
      };

      cursor = {
        package = pkgs.nordzy-cursor-theme;
        name = "Nordzy-cursors";
        size = 24;
      };

      # Targets where blackmatter owns the deep customization.
      # All other Stylix targets (gtk, bat, k9s, fzf, zsh-syntax-highlighting,
      # etc.) default to enabled and are auto-themed by Stylix.
      targets.ghostty.enable = false;   # blackmatter owns detailed Nord palette
      targets.neovim.enable = false;    # blackmatter owns nord.nvim + custom highlights
      targets.starship.enable = false;  # blackmatter owns custom snowflake format
    }; })
  ];
}
