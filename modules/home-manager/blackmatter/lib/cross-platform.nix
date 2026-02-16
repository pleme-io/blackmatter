# Home-manager cross-platform compatibility
{ lib, config, pkgs, ... }:
let
  platform = import ../../../../lib/platform.nix { 
    inherit lib; 
    stdenv = pkgs.stdenv;
  };
in {
  options.blackmatter.crossPlatform = with lib; {
    enable = mkEnableOption "Cross-platform home configuration";
    
    # Platform-aware package selection
    packages = {
      common = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Packages for all platforms";
      };
      
      darwin = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Darwin-only packages";
      };
      
      linux = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Linux-only packages";
      };
    };
    
    # Platform-specific program configurations
    programs = {
      # Terminal emulator
      terminal = mkOption {
        type = types.enum [ "alacritty" "kitty" "iterm2" "gnome-terminal" "auto" ];
        default = "auto";
        description = "Preferred terminal emulator";
      };
      
      # File manager
      fileManager = mkOption {
        type = types.enum [ "ranger" "nnn" "finder" "nautilus" "auto" ];
        default = "auto";
        description = "Preferred file manager";
      };
    };
  };
  
  config = lib.mkIf config.blackmatter.crossPlatform.enable {
    # Install platform-specific packages
    home.packages = 
      config.blackmatter.crossPlatform.packages.common
      ++ lib.optionals platform.platform.isDarwin config.blackmatter.crossPlatform.packages.darwin
      ++ lib.optionals platform.platform.isLinux config.blackmatter.crossPlatform.packages.linux;
    
    # Platform-specific program configurations
    programs = {
      # Bash configuration (cross-platform)
      bash = {
        initExtra = ''
          # Cross-platform clipboard functions
          if command -v pbcopy >/dev/null 2>&1; then
            alias clip='pbcopy'
            alias paste='pbpaste'
          elif command -v xclip >/dev/null 2>&1; then
            alias clip='xclip -selection clipboard'
            alias paste='xclip -selection clipboard -o'
          fi
          
          # Cross-platform open command
          if command -v open >/dev/null 2>&1; then
            : # macOS has open
          elif command -v xdg-open >/dev/null 2>&1; then
            alias open='xdg-open'
          fi
        '';
      };
      
      # Zsh configuration (cross-platform)
      zsh = lib.mkIf config.programs.zsh.enable {
        initExtra = ''
          # Cross-platform clipboard functions
          if [[ "$OSTYPE" == "darwin"* ]]; then
            alias clip='pbcopy'
            alias paste='pbpaste'
          else
            alias clip='xclip -selection clipboard'
            alias paste='xclip -selection clipboard -o'
          fi
          
          # Cross-platform open command
          if [[ "$OSTYPE" != "darwin"* ]]; then
            alias open='xdg-open'
          fi
        '';
      };
      
      # Git configuration (cross-platform)
      git = {
        extraConfig = {
          core = {
            # Use native line endings
            autocrlf = if platform.platform.isDarwin then "input" else "false";
          };
          
          # Platform-specific credential helpers
          credential = lib.mkMerge [
            (lib.mkIf platform.platform.isDarwin {
              helper = "osxkeychain";
            })
            (lib.mkIf platform.platform.isLinux {
              helper = "libsecret";
            })
          ];
        };
      };
      
      # SSH configuration
      ssh = {
        extraConfig = lib.optionalString platform.platform.isDarwin ''
          # macOS-specific SSH configuration
          UseKeychain yes
          AddKeysToAgent yes
        '';
      };
    };
    
    # Platform-specific dotfiles
    home.file = {
      # macOS-specific
      ".hushlogin" = lib.mkIf platform.platform.isDarwin {
        text = "";  # Suppress login message
      };
      
      # Linux-specific
      ".xinitrc" = lib.mkIf (platform.platform.isLinux && config.blackmatter.crossPlatform.programs.terminal == "auto") {
        text = ''
          #!/bin/sh
          exec startx
        '';
        executable = true;
      };
    };
    
    # Platform-specific environment variables
    home.sessionVariables = {
      # Editor selection
      EDITOR = 
        if config.programs.neovim.enable then "nvim"
        else if config.programs.vim.enable then "vim"
        else if platform.platform.isDarwin then "nano"
        else "vi";
      
      # Pager selection
      PAGER = 
        if config.programs.bat.enable then "bat"
        else "less";
    } // lib.optionalAttrs platform.platform.isDarwin {
      # macOS-specific
      HOMEBREW_NO_ANALYTICS = "1";
      HOMEBREW_NO_AUTO_UPDATE = "1";
    } // lib.optionalAttrs platform.platform.isLinux {
      # Linux-specific
      BROWSER = "firefox";
      TERMINAL = 
        if config.blackmatter.crossPlatform.programs.terminal != "auto"
        then config.blackmatter.crossPlatform.programs.terminal
        else "xterm";
    };
    
    # Platform-specific aliases
    home.shellAliases = {
      # Common aliases
      ll = "ls -la";
      la = "ls -a";
    } // lib.optionalAttrs platform.platform.isDarwin {
      # macOS aliases
      updatedb = "sudo /usr/libexec/locate.updatedb";
      flushdns = "sudo dscacheutil -flushcache";
    } // lib.optionalAttrs platform.platform.isLinux {
      # Linux aliases
      open = "xdg-open";
      pbcopy = "xclip -selection clipboard";
      pbpaste = "xclip -selection clipboard -o";
    };
  };
}