# modules/nixos/blackmatter/profiles/hypr-nord/default.nix
# Nord-themed Hyprland profile with nm-applet - System level configuration
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.hypr-nord;
in {
  options = {
    blackmatter = {
      profiles = {
        hypr-nord = {
          enable = mkEnableOption "enable the hypr-nord profile (Nord-themed Hyprland with nm-applet)";

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
    programs.niri.enable = mkForce false;

    # Time zone
    time.timeZone = cfg.timeZone;

    # Enable Hyprland
    programs.hyprland.enable = true;

    # Display manager - greetd with tuigreet
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
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

    # XDG portals for Hyprland
    xdg.portal.enable = true;
    xdg.portal.wlr.enable = true;
    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    xdg.portal.config.common.default = "*";

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

    # Essential packages for Hyprland
    environment.systemPackages = with pkgs; [
      # Core tools
      vim
      wget
      git

      # Terminal
      ghostty
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

      # Network GUI - nm-applet for wifi management
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

      # Hyprland tools
      hyprpicker
      hyprpaper
      hypridle
      hyprlock
      hyprcursor
    ];

    # Performance
    powerManagement.cpuFreqGovernor = "performance";
  };
}
