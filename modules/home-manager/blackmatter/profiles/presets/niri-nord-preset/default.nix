# Niri-Nord Preset - Nord-themed Niri compositor desktop
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.niri-nord-preset;
in {
  options.blackmatter.profiles.presets.niri-nord-preset = {
    enable = mkEnableOption "Niri-Nord preset (Niri with Nord theme and nm-applet)";
  };

  config = mkIf cfg.enable {
    # Use base desktop profile (includes all package sets)
    blackmatter.profiles.base.desktop.enable = true;

    # Use Niri variant with nm-applet
    blackmatter.profiles.variants.niri.enable = true;
    blackmatter.profiles.variants.niri.enableNetworkManager = true;

    # Use Nord theme
    blackmatter.themes.nord.enable = true;
    blackmatter.themes.nord.gtk.enable = true;
    blackmatter.themes.nord.qt.enable = true;

    # Niri configuration with Nord theming
    home.file.".config/niri/config.kdl".text = ''
      input {
          keyboard {
              xkb { layout "us" }
          }
          touchpad {
              tap
              natural-scroll
          }
      }

      layout {
          gaps 8
          focus-ring {
              width 2
              active-color "#88c0d0"
              inactive-color "#3b4252"
          }
      }

      spawn-at-startup "waybar"
      spawn-at-startup "mako"
      spawn-at-startup "nm-applet" "--indicator"

      cursor {
          xcursor-theme "Nordzy-cursors"
          xcursor-size 24
      }

      binds {
          Mod+Q { close-window; }
          Mod+Return { spawn "alacritty"; }
          Mod+D { spawn "fuzzel"; }

          // Vim navigation
          Mod+H { focus-column-left; }
          Mod+J { focus-window-down; }
          Mod+K { focus-window-up; }
          Mod+L { focus-column-right; }

          // Move windows
          Mod+Shift+H { move-column-left; }
          Mod+Shift+J { move-window-down; }
          Mod+Shift+K { move-window-up; }
          Mod+Shift+L { move-column-right; }

          // Workspaces
          Mod+1 { focus-workspace 1; }
          Mod+2 { focus-workspace 2; }
          Mod+3 { focus-workspace 3; }
          Mod+4 { focus-workspace 4; }

          Mod+Shift+1 { move-column-to-workspace 1; }
          Mod+Shift+2 { move-column-to-workspace 2; }
          Mod+Shift+3 { move-column-to-workspace 3; }
          Mod+Shift+4 { move-column-to-workspace 4; }

          Mod+F { maximize-column; }
          Mod+Escape { spawn "swaylock" "-f"; }

          Print { screenshot; }
      }
    '';
  };
}
