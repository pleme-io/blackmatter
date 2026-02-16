# modules/nixos/blackmatter/profiles/niri-nord/default.nix
# Nord-themed niri compositor profile - System level configuration
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.niri-nord;
in {
  options = {
    blackmatter = {
      profiles = {
        niri-nord = {
          enable = mkEnableOption "enable the niri-nord profile (Nord-themed niri compositor)";

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
    # Disable conflicting desktop managers (using nixos-24.11 paths)
    services.xserver.desktopManager.gnome.enable = mkForce false;
    services.xserver.displayManager.gdm.enable = mkForce false;

    # Time zone
    time.timeZone = cfg.timeZone;

    # Enable niri compositor
    programs.niri.enable = true;

    # Display manager - greetd with tuigreet
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
          user = "greeter";
        };
      };
    };

    # Essential services
    services.dbus.enable = true;
    services.udev.enable = true;
    services.printing.enable = true;
    hardware.graphics.enable = true;
    security.rtkit.enable = true;
    security.polkit.enable = true;
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

    # XDG portals
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    xdg.portal.config.common.default = "gtk";

    # Fonts
    fonts.packages = with pkgs; [
      fira-code
      fira-code-symbols
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
      dejavu_fonts
      noto-fonts
      noto-fonts-color-emoji
      liberation_ttf
      inter
      jetbrains-mono
      cascadia-code
    ];

    # Essential packages for niri
    environment.systemPackages = with pkgs; [
      # Core tools
      vim
      wget
      git

      # Terminal
      alacritty
      kitty

      # App launcher
      fuzzel
      rofi

      # Screenshot
      grim
      slurp
      wl-clipboard

      # Notifications
      mako
      libnotify

      # Controls
      brightnessctl
      pamixer
      playerctl

      # File manager
      xfce.thunar

      # Lock screen
      swaylock
      swayidle

      # System tray and status
      waybar

      # Network GUI
      networkmanagerapplet

      # Password management
      gnome-keyring
      seahorse

      # Polkit agent
      polkit_gnome

      # Viewers
      imv
      zathura

      # Nord themes
      nordic
      papirus-nord
      nordzy-cursor-theme
    ];

    # Performance
    powerManagement.cpuFreqGovernor = "performance";
  };
}
