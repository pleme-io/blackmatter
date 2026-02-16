# Nord Theme - Comprehensive theming for all components
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.themes.nord;
  colors = import ./colors.nix;
in {
  options.blackmatter.themes.nord = {
    enable = mkEnableOption "Nord theme for all blackmatter components";

    gtk = {
      enable = mkOption {
        type = types.bool;
        default = cfg.enable;
        description = "Enable Nord theme for GTK applications";
      };
    };

    qt = {
      enable = mkOption {
        type = types.bool;
        default = cfg.enable;
        description = "Enable Nord theme for Qt applications";
      };
    };

    colors = mkOption {
      type = types.attrs;
      default = colors;
      description = "Nord color palette";
      readOnly = true;
    };
  };

  config = mkMerge [
    (mkIf cfg.gtk.enable {
      # GTK theme
      gtk = {
        enable = true;
        theme = {
          name = "Nordic";
          package = pkgs.nordic;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-nord;
        };
        cursorTheme = {
          name = "Nordzy-cursors";
          package = pkgs.nordzy-cursor-theme;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };

      # Install GTK theme packages
      home.packages = with pkgs; [
        nordic
        papirus-nord
        nordzy-cursor-theme
      ];
    })

    (mkIf cfg.qt.enable {
      # Qt theme
      qt = {
        enable = true;
        platformTheme.name = "gtk";
        style.name = "adwaita-dark";
      };
    })
  ];
}
