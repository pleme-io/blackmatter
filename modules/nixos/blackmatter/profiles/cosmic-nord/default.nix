# modules/nixos/blackmatter/profiles/cosmic-nord/default.nix
# Nord-themed COSMIC desktop profile - System level configuration
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.cosmic-nord;
in {
  options = {
    blackmatter = {
      profiles = {
        cosmic-nord = {
          enable = mkEnableOption "enable the cosmic-nord profile (Nord-themed COSMIC desktop)";

          timeZone = mkOption {
            type = types.str;
            default = "UTC";
            description = "System timezone";
            example = "America/New_York";
          };
        };
      };
    };
  };

  config = mkIf (cfg.enable) {
    # Disable conflicting desktop managers
    services.desktopManager.gnome.enable = mkForce false;
    services.displayManager.gdm.enable = mkForce false;
    programs.niri.enable = mkForce false;

    # Time zone
    time.timeZone = cfg.timeZone;

    # Enable COSMIC desktop and greeter
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;

    # Essential services
    services.dbus.enable = true;
    services.udev.enable = true;
    services.printing.enable = true;
    hardware.graphics.enable = true;
    security.rtkit.enable = true;
    services.libinput.enable = true;

    # Audio with PipeWire
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    # NetworkManager for WiFi GUI
    networking.networkmanager.enable = true;

    # XDG portals for COSMIC
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];

    # Fonts
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

    # COSMIC-specific packages
    environment.systemPackages = with pkgs; [
      # Core tools
      vim
      wget
      git

      # COSMIC apps
      cosmic-term
      cosmic-files
      cosmic-edit

      # Network GUI
      networkmanagerapplet

      # Password management
      gnome-keyring
      seahorse
    ];

    # Performance
    powerManagement.cpuFreqGovernor = "performance";
  };
}
