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

    # Override the base16 scheme stylix consumes. Generic blackmatter
    # can't reference a flake input, so the nix repo (which owns the
    # ishou input) sets this to the ishou-rendered Borealis base16 yaml
    # — keeping "colors are born in ishou" true while leaving the
    # default (the bundled Nord scheme) unchanged for any consumer that
    # doesn't set it. `null` = use the built-in default.
    base16SchemePath = mkOption {
      type = types.nullOr (types.either types.path types.str);
      default = null;
      description = ''
        Path to a base16 scheme YAML for stylix. When null, the bundled
        Nord scheme is used. The nix repo sets this to ishou's
        stylix-base16-borealis-night output so foreign apps inherit the
        prescribed fleet (Borealis) palette from the single ishou source.
      '';
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
