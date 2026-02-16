# Enhanced Blizzard Profile for Home-Manager
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard = {
    enable = mkEnableOption "Blizzard desktop profile for user environment";
    
    # Feature flags
    features = {
      desktop = {
        windowManager = mkOption {
          type = types.enum [ "hyprland" "i3" "sway" "none" ];
          default = "hyprland";
          description = "Window manager to use";
        };
        
        terminal = mkOption {
          type = types.enum [ "alacritty" "kitty" "wezterm" ];
          default = "alacritty";
          description = "Terminal emulator";
        };
        
        browser = mkOption {
          type = types.enum [ "firefox" "chrome" "brave" ];
          default = "firefox";
          description = "Web browser";
        };
        
        theme = mkOption {
          type = types.enum [ "nord" "dracula" "catppuccin" "gruvbox" ];
          default = "nord";
          description = "Color theme";
        };
      };
      
      shell = {
        type = mkOption {
          type = types.enum [ "zsh" "bash" "fish" ];
          default = "zsh";
          description = "Shell to use";
        };
        
        starship = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Starship prompt";
        };
        
        tmux = mkOption {
          type = types.bool;
          default = true;
          description = "Enable tmux";
        };
      };
      
      development = {
        neovim = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Neovim with full configuration";
        };
        
        languages = mkOption {
          type = types.listOf types.str;
          default = [ "nix" "bash" ];
          description = "Programming language support";
        };
        
        tools = mkOption {
          type = types.listOf types.str;
          default = [ "git" "fzf" "ripgrep" ];
          description = "Development tools";
        };
      };
      
      multimedia = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable multimedia CLI/TUI tools";
        };
        
        categories = mkOption {
          type = types.listOf types.str;
          default = [ "audio" "video" "image" "document" ];
          description = "Multimedia tool categories to enable";
        };
        
        textArt = mkOption {
          type = types.bool;
          default = true;
          description = "Enable text art and terminal fun tools";
        };
      };
      
      packages = {
        ecosystems = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Package ecosystems to enable";
          example = [ "webDevelopment" "cloudInfrastructure" ];
        };
        
        categories = mkOption {
          type = types.listOf types.str;
          default = [];
          description = "Package categories to enable";
          example = [ "golang" "rust" "kubernetes" ];
        };
      };
    };
    
    # Custom packages
    additionalPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to install";
    };
  };
  
  config = mkIf cfg.enable (mkMerge [
    # Core configuration
    {
      # Enable base components based on features
      blackmatter.components = {
        # Desktop
        desktop = {
          enable = cfg.features.desktop.windowManager != "none";
          
          # Window managers
          hyprland.enable = cfg.features.desktop.windowManager == "hyprland";
          i3.enable = cfg.features.desktop.windowManager == "i3";
          sway.enable = cfg.features.desktop.windowManager == "sway";
          
          # Terminal emulators
          alacritty.enable = cfg.features.desktop.terminal == "alacritty";
          kitty.enable = cfg.features.desktop.terminal == "kitty";
          
          # Browsers
          firefox.enable = cfg.features.desktop.browser == "firefox";
          chrome.enable = cfg.features.desktop.browser == "chrome";
        };
        
        # Shell (all plugins managed by Nix, no runtime plugin managers)
        shell = {
          enable = true;
          tmux.enable = cfg.features.shell.tmux;

          # Package management
          packages = {
            enable = true;

            # Enable ecosystems based on features (simplified for now)
            ecosystems.enable = cfg.features.packages.ecosystems != [];

            # Enable categories based on features (simplified for now)
            categories.enable = cfg.features.packages.categories != [];
          };
        };
        
        # Development
        nvim.enable = cfg.features.development.neovim;
      };
      
      # Additional packages based on features
      home.packages = with pkgs; cfg.additionalPackages ++ 
        optionals (elem "git" cfg.features.development.tools) [ git git-lfs ] ++
        optionals (elem "fzf" cfg.features.development.tools) [ fzf ] ++
        optionals (elem "ripgrep" cfg.features.development.tools) [ ripgrep ] ++
        optionals (elem "fd" cfg.features.development.tools) [ fd ] ++
        optionals (elem "bat" cfg.features.development.tools) [ bat ] ++
        optionals (elem "eza" cfg.features.development.tools) [ eza ] ++
        optionals (elem "jq" cfg.features.development.tools) [ jq yq ] ++
        
        # Multimedia CLI/TUI tools (Round 5)
        optionals (cfg.features.multimedia.enable && elem "audio" cfg.features.multimedia.categories) [
          # Audio players
          cmus ncmpcpp moc mpv vlc mplayer ffplay
          # Audio tools
          sox ffmpeg lame flac vorbis-tools opus-tools
          yt-dlp youtube-dl aria2 streamlink
          mediainfo exiftool aubio beets picard
          alsamixer pulsemixer pamixer playerctl cava
        ] ++
        optionals (cfg.features.multimedia.enable && elem "video" cfg.features.multimedia.categories) [
          # Video processing and analysis
          ffmpeg x264 x265 # handbrake # Disabled: ffmpeg-full LCEVC compatibility
          dvdbackup
          mediainfo ffprobe mkvtoolnix mp4v2 atomicparsley
          v4l-utils obs-studio
        ] ++
        optionals (cfg.features.multimedia.enable && elem "image" cfg.features.multimedia.categories) [
          # Image processing and viewing
          imagemagick graphicsmagick optipng jpegoptim pngcrush
          webp libavif feh sxiv fim tiv catimg chafa viu
          exiftool jhead jpeginfo pnginfo qrencode zbar
        ] ++
        optionals (cfg.features.multimedia.enable && elem "document" cfg.features.multimedia.categories) [
          # Document conversion and processing
          pandoc ghostscript poppler_utils qpdf pdftk pdfgrep mupdf
          groff asciidoc asciidoctor markdown multimarkdown
          aspell hunspell languagetool dict wordnet
        ] ++
        optionals (cfg.features.multimedia.enable && cfg.features.multimedia.textArt) [
          # Text art and terminal fun
          figlet toilet boxes cowsay fortune lolcat cmatrix 
          asciiquarium sl neofetch fastfetch
        ];
    }
    
    # Theme configuration
    (mkIf (cfg.features.desktop.theme == "nord") {
      # Apply Nord theme
      programs = {
        alacritty.settings.colors = mkIf (cfg.features.desktop.terminal == "alacritty") {
          primary = {
            background = "#2E3440";
            foreground = "#D8DEE9";
          };
          normal = {
            black = "#3B4252";
            red = "#BF616A";
            green = "#A3BE8C";
            yellow = "#EBCB8B";
            blue = "#81A1C1";
            magenta = "#B48EAD";
            cyan = "#88C0D0";
            white = "#E5E9F0";
          };
        };
        
        kitty.theme = mkIf (cfg.features.desktop.terminal == "kitty") "Nord";
      };
    })
    
    # Shell-specific configuration
    # All shell config (aliases, plugins, prompt) managed by blackmatter.components.shell
    # No programs.zsh or oh-my-zsh - everything is Nix-managed via groups and plugins
    
    # Language-specific configuration
    (mkMerge (map (lang: mkIf (elem lang cfg.features.development.languages) (
      if lang == "rust" then {
        home.packages = with pkgs; [ rustc cargo rust-analyzer rustfmt clippy ];
        home.sessionVariables.CARGO_HOME = "$HOME/.cargo";
      } else if lang == "go" then {
        home.packages = with pkgs; [ go gopls delve ];
        home.sessionVariables = {
          GOPATH = "$HOME/go";
          GOBIN = "$HOME/go/bin";
        };
      } else if lang == "python" then {
        home.packages = with pkgs; [ 
          python3 
          python3Packages.pip 
          python3Packages.virtualenv
          python3Packages.black
          python3Packages.pylint
        ];
      } else if lang == "javascript" then {
        home.packages = with pkgs; [ 
          nodejs
          nodePackages.npm
          nodePackages.yarn
          nodePackages.typescript
          nodePackages.prettier
        ];
      } else {}
    )) cfg.features.development.languages))
  ]);
}