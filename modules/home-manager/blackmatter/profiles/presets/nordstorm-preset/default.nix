# Nordstorm Preset - Nord-themed GNOME desktop with Forge tiling
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.nordstorm-preset;
  inherit (lib.gvariant) mkTuple;

  # Nord color palette (from theme system)
  nord = config.blackmatter.themes.nord.colors or {
    # Fallback if theme not enabled
    nord0 = "#2e3440";
    nord1 = "#3b4252";
    nord2 = "#434c5e";
    nord3 = "#4c566a";
    nord4 = "#d8dee9";
    nord5 = "#e5e9f0";
    nord6 = "#eceff4";
    nord7 = "#8fbcbb";
    nord8 = "#88c0d0";
    nord9 = "#81a1c1";
    nord10 = "#5e81ac";
    nord11 = "#bf616a";
    nord12 = "#d08770";
    nord13 = "#ebcb8b";
    nord14 = "#a3be8c";
    nord15 = "#b48ead";
  };
in {
  options.blackmatter.profiles.presets.nordstorm-preset = {
    enable = mkEnableOption "Nordstorm preset (Nord-themed GNOME with Forge tiling)";
  };

  config = mkIf cfg.enable {
    # Use base desktop profile (includes all package sets)
    blackmatter.profiles.base.desktop.enable = true;

    # Use Nord theme
    blackmatter.themes.nord.enable = true;
    blackmatter.themes.nord.gtk.enable = true;
    blackmatter.themes.nord.qt.enable = true;

    # GNOME-specific packages
    home.packages = with pkgs; [
      # GNOME Extensions - minimal and performance-focused
      gnomeExtensions.user-themes
      gnomeExtensions.dash-to-dock
      gnomeExtensions.blur-my-shell
      gnomeExtensions.arcmenu
      gnomeExtensions.vitals
      gnomeExtensions.just-perfection
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.app-icons-taskbar
      gnomeExtensions.caffeine

      # Core productivity extensions
      gnomeExtensions.forge # i3/sway-style tiling window manager

      # Workspace management
      gnomeExtensions.workspace-indicator # Show current workspace in top bar
      gnomeExtensions.auto-move-windows # Auto-assign apps to workspaces

      # Clipboard and history
      gnomeExtensions.clipboard-history # Enhanced clipboard with history

      # System monitoring
      gnomeExtensions.freon # CPU/GPU temps and fan speeds
      gnomeExtensions.resource-monitor # System resource usage in top bar

      # Developer tools
      gnomeExtensions.vscode-search-provider # VSCode project search in overview

      # Additional tools
      gnome-tweaks
      dconf-editor

      # Web browsers
      google-chrome # Primary browser for development
      chromium # Open-source alternative

      # Terminal emulators
      ghostty # Primary terminal - fast, GPU-accelerated
      kitty # Alternative - feature-rich
      alacritty # Alternative - minimal, fast

      # Development tools
      gnome-builder # GNOME's native IDE
      meld # Visual diff/merge tool

      # File managers and navigation
      ranger # Terminal file manager
      nnn # Minimal fast file manager
      yazi # Modern terminal file manager
    ];

    # dconf settings for GNOME
    dconf.settings = {
      # Enable installed extensions
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "dash-to-dock@micxgx.gmail.com"
          "blur-my-shell@aunetx"
          "arcmenu@arcmenu.com"
          "Vitals@CoreCoding.com"
          "just-perfection-desktop@just-perfection"
          "clipboard-indicator@tudmotu.com"
          "caffeine@patapon.info"
          # Productivity and performance
          "forge@jmmaranan.com"
          # Workspace management
          "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
          "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
          # Development extensions
          "clipboard-history@alexsaveau.dev"
          "freon@UshakovVasilii_Github.yahoo.com"
          "vscode-search-provider@adrianmanchev.gitlab.io"
          "Resource_Monitor@Ory0n"
        ];
        favorite-apps = [
          "ghostty.desktop"
          "google-chrome.desktop"
          "code.desktop"
          "org.gnome.Nautilus.desktop"
        ];
      };

      # Shell theme
      "org/gnome/shell/extensions/user-theme" = {
        name = "Nordic";
      };

      # Dash to Dock configuration
      "org/gnome/shell/extensions/dash-to-dock" = {
        dock-position = "BOTTOM";
        dash-max-icon-size = 48;
        show-trash = false;
        show-mounts = false;
        transparency-mode = "FIXED";
        background-opacity = 0.7;
        custom-theme-shrink = true;
        dock-fixed = false;
        intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      };

      # Blur my shell
      "org/gnome/shell/extensions/blur-my-shell" = {
        brightness = 0.6;
        sigma = 30;
      };

      # Interface preferences
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Nordic";
        icon-theme = "Papirus-Dark";
        cursor-theme = "Nordzy-cursors";
        font-name = "Inter 11";
        document-font-name = "Inter 11";
        monospace-font-name = "JetBrains Mono 10";
        clock-show-weekday = true;
        enable-hot-corners = true;
        show-battery-percentage = true;

        # Disable animations for app switching
        enable-animations = false;
      };

      # Window manager preferences
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
        titlebar-font = "Inter Bold 11";
        theme = "Nordic";

        # Disable focus mode visual indicators
        focus-mode = "sloppy";
      };

      # Mutter (window manager) settings - Performance optimized
      "org/gnome/mutter" = {
        edge-tiling = true;
        dynamic-workspaces = true;
        workspaces-only-on-primary = true;

        # Performance tweaks
        experimental-features = ["scale-monitor-framebuffer"]; # Better multi-monitor perf
        check-alive-timeout = 10000; # Faster unresponsive app detection
      };

      # Background with Nord colors
      "org/gnome/desktop/background" = {
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/adwaita-l.jxl";
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/adwaita-d.jxl";
        primary-color = nord.nord0;
        secondary-color = nord.nord1;
      };

      # Terminal color scheme (Nord)
      "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
        visible-name = "Nord";
        palette = [
          nord.nord1 # black
          nord.nord11 # red
          nord.nord14 # green
          nord.nord13 # yellow
          nord.nord9 # blue
          nord.nord15 # magenta
          nord.nord8 # cyan
          nord.nord5 # white
          nord.nord3 # bright black
          nord.nord11 # bright red
          nord.nord14 # bright green
          nord.nord13 # bright yellow
          nord.nord9 # bright blue
          nord.nord15 # bright magenta
          nord.nord7 # bright cyan
          nord.nord6 # bright white
        ];
        background-color = nord.nord0;
        foreground-color = nord.nord4;
        use-theme-colors = false;
        use-theme-transparency = false;
        cursor-background-color = nord.nord4;
        cursor-foreground-color = nord.nord0;
      };

      # Input sources - US keyboard only
      "org/gnome/desktop/input-sources" = {
        sources = [
          (mkTuple ["xkb" "us"])
        ];
        xkb-options = ["terminate:ctrl_alt_bksp" "caps:escape"];
      };

      # Keyboard shortcuts
      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Super>q"];
        toggle-maximized = ["<Super>m"];
        switch-to-workspace-left = ["<Super>Left"];
        switch-to-workspace-right = ["<Super>Right"];
        move-to-workspace-left = ["<Super><Shift>Left"];
        move-to-workspace-right = ["<Super><Shift>Right"];
      };

      # Custom keybindings for terminal
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal" = {
        name = "Launch Ghostty Terminal";
        command = "ghostty";
        binding = "<Super>Return";
      };

      # Forge - i3/sway-style tiling (matches Hyprland workflow)
      "org/gnome/shell/extensions/forge" = {
        # Tiling behavior
        auto-split-enabled = true;
        split-border-toggle = false; # No visual border on splits
        tiling-mode-enabled = true;

        # Window gaps (like Hyprland)
        window-gap-size = 4;
        window-gap-size-increment = 1;

        # Disable focus borders/highlights
        focus-border-toggle = false;

        # Workspace behavior
        workspace-skip-tile = "0"; # Tile on all workspaces
      };

      # Forge keybindings (matching Hyprland Super+h/j/k/l)
      "org/gnome/shell/extensions/forge/keybindings" = {
        # Window navigation (Vim-style, like Hyprland)
        focus-left = ["<Super>h"];
        focus-down = ["<Super>j"];
        focus-up = ["<Super>k"];
        focus-right = ["<Super>l"];

        # Window movement
        move-left = ["<Super><Shift>h"];
        move-down = ["<Super><Shift>j"];
        move-up = ["<Super><Shift>k"];
        move-right = ["<Super><Shift>l"];

        # Split orientation
        split-horizontal = ["<Super>s"];
        split-vertical = ["<Super>v"];

        # Toggle tiling/floating
        toggle-tiling = ["<Super>t"];

        # Gaps
        gap-increase = ["<Super>plus"];
        gap-decrease = ["<Super>minus"];
      };

      # Just Perfection - Performance tweaks (disable all visual fluff)
      "org/gnome/shell/extensions/just-perfection" = {
        animation = 0; # Disable animations completely
        workspace-popup = false; # Disable popup for faster switching
        workspace-switcher-should-show = false; # Hide workspace switcher popup
        startup-status = 0; # Faster startup
        window-picker-icon = false; # No icon in overview
        panel-notification-icon = true; # Keep notification icon
        osd = false; # Disable on-screen display overlays
      };

      # Workspace Indicator - Minimal display
      "org/gnome/shell/extensions/workspace-indicator" = {
        panel-position = "center";
      };

      # Auto Move Windows - Assign apps to workspaces
      "org/gnome/shell/extensions/auto-move-windows" = {
        application-list = [
          "ghostty.desktop:1"
          "google-chrome.desktop:2"
          "code.desktop:3"
        ];
      };
    };

    # Kitty terminal with Nord theme
    programs.kitty = {
      enable = true;
      theme = "Nord";
      font = {
        name = "JetBrains Mono";
        size = 11;
      };
      settings = {
        background_opacity = "0.95";
        window_padding_width = 8;
        hide_window_decorations = "yes";
        confirm_os_window_close = 0;
      };
    };

    # Alacritty terminal with Nord theme
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          opacity = 0.95;
          padding = {
            x = 8;
            y = 8;
          };
        };
        font = {
          normal = {
            family = "JetBrains Mono";
            style = "Regular";
          };
          size = 11;
        };
        colors = {
          primary = {
            background = nord.nord0;
            foreground = nord.nord4;
          };
          normal = {
            black = nord.nord1;
            red = nord.nord11;
            green = nord.nord14;
            yellow = nord.nord13;
            blue = nord.nord9;
            magenta = nord.nord15;
            cyan = nord.nord8;
            white = nord.nord5;
          };
          bright = {
            black = nord.nord3;
            red = nord.nord11;
            green = nord.nord14;
            yellow = nord.nord13;
            blue = nord.nord9;
            magenta = nord.nord15;
            cyan = nord.nord7;
            white = nord.nord6;
          };
        };
      };
    };

    # Ghostty terminal with Nord theme (primary terminal)
    # Now using modular component instead of inline config
    blackmatter.components.ghostty = {
      enable = true;
      font = {
        family = "JetBrains Mono";
        size = 11;
        thicken = true;
      };
      window = {
        paddingX = 12;
        paddingY = 12;
        decoration = true;
        gtkTitlebar = true;
      };
      appearance = {
        backgroundOpacity = 0.92;
        backgroundBlurRadius = 20;
        unfocusedSplitOpacity = 0.75;
      };
      cursor = {
        style = "block";
        blink = true;
      };
      theme = {
        nordTheme = true;  # Use Nord colors from theme system
      };
      performance = {
        vsync = true;
        minimumContrast = 1.1;
      };
      behavior = {
        confirmClose = false;
        copyOnSelect = false;
        mouseHideWhileTyping = true;
        scrollbackLimit = 10000;
        gtkSingleInstance = true;
      };
      shellIntegration = {
        enable = true;
        features = ["cursor" "sudo" "title"];
      };
    };

    # Zoxide - Smarter cd with autojump
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # Broot - Interactive tree navigator
    programs.broot = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    # Shell aliases for modern tools
    home.shellAliases = {
      # Use modern Rust alternatives
      cat = "bat";
      ls = "eza --icons --git";
      ll = "eza --icons --git -l";
      la = "eza --icons --git -la";
      tree = "eza --icons --git --tree";
      find = "fd";
      grep = "rg";
      du = "dust";
      ps = "procs";
      top = "btm"; # bottom
      diff = "difft"; # difftastic

      # Productivity aliases
      cd = "z"; # zoxide
      lg = "lazygit";
      gg = "gitui";
    };
  };
}
