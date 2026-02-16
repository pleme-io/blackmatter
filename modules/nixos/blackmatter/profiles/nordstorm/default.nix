# modules/nixos/blackmatter/profiles/nordstorm/default.nix
# Nord-themed GNOME desktop profile - System level configuration
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  imports = [
    ./displayManager
    ./networking
    ./bluetooth
    ./xserver
    ./locale
    ./limits
    ./docker
    ./sound
    ./boot
    ./time
    ./nix
    ../../../../shared/nix-performance.nix
  ];

  options = {
    blackmatter = {
      profiles = {
        nordstorm = {
          enable = mkEnableOption "enable the nordstorm profile (Nord-themed GNOME desktop)";

          console = {
            keyMap = mkOption {
              type = types.str;
              default = "us";
              description = "Console keyboard layout";
              example = "br-abnt2";
            };

            font = mkOption {
              type = types.str;
              default = "Lat2-Terminus16";
              description = "Console font";
            };
          };
        };
      };
    };
  };

  config = mkMerge [
    (mkIf (cfg.enable) {
      # Enable high-performance Nix configuration
      nix.performance.enable = true;

      console = {
        font = cfg.console.font;
        keyMap = cfg.console.keyMap;
      };

      powerManagement.cpuFreqGovernor = "performance";

      # Essential system services
      services.dbus.enable = true;
      services.udev.enable = true;
      services.printing.enable = true;
      services.hardware.bolt.enable = true;
      security.rtkit.enable = true;
      services.seatd.enable = true;
      programs.zsh.enable = true;
      services.libinput.enable = true;

      # XDG portals for GNOME
      xdg.portal.enable = true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];

      # Graphics
      hardware.graphics.enable = true;

      # Essential system packages
      environment.systemPackages = with pkgs; [
        vim
        wget
        git
        bash
        fontconfig
        # GNOME essentials
        gnome-tweaks
        dconf-editor
        gnomeExtensions.user-themes
      ];

      # Fonts configuration with Nord-friendly fonts
      fonts.fontconfig.enable = true;
      fonts.fontDir.enable = true;
      fonts.enableDefaultPackages = true;
      fonts.packages = with pkgs; [
        fira-code
        fira-code-symbols
        nerd-fonts.fira-code
        dejavu_fonts
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
        inter
        jetbrains-mono
        cascadia-code
      ];

      # GNOME and GDM configuration is in ./xserver module

      # Exclude some default GNOME apps to keep system lean
      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        epiphany # GNOME web browser
        geary # email client
        gnome-music
        totem # video player
      ];
    })
  ];
}
