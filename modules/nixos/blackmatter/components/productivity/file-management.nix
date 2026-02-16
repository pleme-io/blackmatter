# File Management & Navigation - Ultimate CLI File Handling
{ config, lib, pkgs, ... }:
let
  cfg = config.blackmatter.productivity.fileManagement;
  errors = import ../../../../lib/errors.nix { inherit lib; };
in {
  options.blackmatter.productivity.fileManagement = with lib; {
    enable = mkEnableOption "Comprehensive file management and navigation tools";
    
    fileManagers = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable terminal file managers";
      };
      
      includeAdvanced = mkOption {
        type = types.bool;
        default = true;
        description = "Include advanced file managers (broot, xplr, felix)";
      };
      
      includeClassic = mkOption {
        type = types.bool;
        default = true;
        description = "Include classic file managers (ranger, nnn, lf)";
      };
    };
    
    searchTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable file search and grep tools";
      };
      
      includeModern = mkOption {
        type = types.bool;
        default = true;
        description = "Include modern search tools (ripgrep, fd, etc.)";
      };
      
      includeClassic = mkOption {
        type = types.bool;
        default = true;
        description = "Include classic search tools (grep, ack, ag)";
      };
    };
    
    treeViews = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable tree view and listing tools";
      };
      
      includeEnhanced = mkOption {
        type = types.bool;
        default = true;
        description = "Include enhanced listing tools (eza, lsd, etc.)";
      };
    };
    
    navigation = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable smart navigation tools";
      };
      
      includeJumpers = mkOption {
        type = types.bool;
        default = true;
        description = "Include directory jumpers (zoxide, autojump, etc.)";
      };
    };
    
    fuzzyFinders = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable fuzzy finding tools";
      };
    };
  };
  
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base validation
    {
      assertions = [
        {
          assertion = cfg.fileManagers.enable || cfg.searchTools.enable || cfg.treeViews.enable || 
                     cfg.navigation.enable || cfg.fuzzyFinders.enable;
          message = errors.format.formatError (
            errors.types.configError "At least one file management category must be enabled" {
              available = "fileManagers, searchTools, treeViews, navigation, fuzzyFinders";
            }
          );
        }
      ];
    }
    
    # File Managers Collection
    (lib.mkIf cfg.fileManagers.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Classic terminal file managers
          (lib.optionals cfg.fileManagers.includeClassic [
            ranger                 # Python-based file manager with VI key bindings
            nnn                    # Fast, feature-rich terminal file manager
            lf                     # Terminal file manager written in Go
            mc                     # Midnight Commander - dual-pane file manager
            vifm                   # Vi-like file manager
          ]) ++
          
          # Advanced/Modern file managers
          (lib.optionals cfg.fileManagers.includeAdvanced [
            broot                  # Interactive tree view with fuzzy search
            xplr                   # Hackable, minimal, fast file explorer
            felix                  # Modern file manager with git integration
            yazi                   # Blazing fast terminal file manager
            clifm                  # Shell-like, command line file manager
            joshuto               # Ranger-like file manager in Rust
          ])
        );
        
      # Shell aliases for file managers
      environment.shellAliases = {
        fm = "ranger";
        files = "nnn";
        browse = "broot";
        explore = "xplr";
      };
    })
    
    # Search Tools Collection
    (lib.mkIf cfg.searchTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Modern search tools (Rust-based and fast)
          (lib.optionals cfg.searchTools.includeModern [
            ripgrep                # Ultra-fast text search (rg)
            fd                     # Simple, fast alternative to find
            sd                     # Intuitive find & replace CLI
            choose                 # Human-friendly alternative to cut/awk
            ugrep                  # Ultra-fast grep with better UX
          ]) ++
          
          # Classic search tools
          (lib.optionals cfg.searchTools.includeClassic [
            silver-searcher        # Fast code searching tool (ag)
            ack                    # Grep-like tool for programmers
            pcregrep              # Perl-compatible regex grep
            gawk                   # GNU awk for pattern scanning
            gnugrep               # GNU grep
          ]) ++
          
          # Specialized search tools
          [
            pdfgrep               # Search in PDF files
            recoll                # Desktop search tool
            locate                # File location database
            mlocate               # Secure locate implementation
          ]
        );
        
      # Enhanced grep aliases
      environment.shellAliases = lib.mkMerge [
        (lib.mkIf cfg.searchTools.includeModern {
          grep = "rg";
          find = "fd";
          search = "rg -i";
          fsearch = "fd -i";
        })
        
        (lib.mkIf cfg.searchTools.includeClassic {
          ag = "ag --color-match='1;32'";
          ack = "ack --color-match=bold_green";
        })
      ];
    })
    
    # Tree Views and Listing Tools
    (lib.mkIf cfg.treeViews.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Essential tree tools
          [
            tree                   # Classic directory tree display
            ptree                  # Python implementation of tree
          ] ++
          
          # Enhanced listing tools
          (lib.optionals cfg.treeViews.includeEnhanced [
            eza                    # Modern replacement for ls (successor to exa)
            lsd                    # Next gen ls with icons and colors
            logo-ls               # Modern ls with file type icons
            colorls               # Beautify ls command with colors
          ]) ++
          
          # Directory analysis tools
          [
            ncdu                   # NCurses disk usage analyzer
            du-dust               # More intuitive version of du
            duf                    # Better df alternative
            diskus                # Fast disk usage analyzer
          ]
        );
        
      # Enhanced listing aliases
      environment.shellAliases = lib.mkMerge [
        {
          l = "eza -la --icons --git";
          ll = "eza -la --icons --git --header";
          lt = "eza --tree --level=2 --icons";
          ltree = "tree -aC";
          lsize = "du-dust";
          usage = "ncdu";
        }
        
        (lib.mkIf cfg.treeViews.includeEnhanced {
          ls = "eza --icons";
          la = "eza -la --icons";
          lh = "eza -la --icons --header";
        })
      ];
    })
    
    # Navigation Tools
    (lib.mkIf cfg.navigation.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Directory jumpers
          (lib.optionals cfg.navigation.includeJumpers [
            zoxide                 # Smarter cd command (z)
            autojump              # Jump to frequently used directories
            fasd                  # Command-line productivity booster
            z-lua                 # Fast cd command that learns
          ]) ++
          
          # Navigation utilities
          [
            pushd                 # Directory stack manipulation
            dirs                  # Show directory stack
            cdpath                # Enhanced cd with path search
          ] ++
          
          # Path manipulation tools
          [
            realpath              # Print resolved path
            readlink              # Display symbolic link targets
            dirname               # Extract directory name
            basename              # Extract filename
          ]
        );
        
      # Navigation aliases
      environment.shellAliases = {
        j = "z";                  # Jump with zoxide
        ji = "zi";                # Interactive jump
        back = "cd -";            # Go back
        home = "cd ~";            # Go home
        root = "cd /";            # Go to root
        ".." = "cd ..";           # Go up one level
        "..." = "cd ../..";       # Go up two levels
        "...." = "cd ../../..";   # Go up three levels
      };
    })
    
    # Fuzzy Finders Collection
    (lib.mkIf cfg.fuzzyFinders.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] [
          fzf                     # Command-line fuzzy finder
          skim                    # Fuzzy finder in Rust (alternative to fzf)
          peco                    # Simplistic interactive filtering tool
          percol                  # Interactive grep tool
          fselect               # Find files with SQL-like queries
        ];
        
      # Fuzzy finder aliases and functions
      environment.shellAliases = {
        preview = "fzf --preview 'bat --color=always --style=header,grid --line-range :300 {}'";
        fcd = "cd $(fd --type d | fzf)";
        fopen = "xdg-open $(fzf)";
        fedit = "$EDITOR $(fzf)";
      };
    })
    
    # Integration and Enhancement
    {
      # Ensure bat is available for previews
      environment.systemPackages = with pkgs; [
        bat                     # Cat clone with syntax highlighting
        file                    # File type detection
        mediainfo              # Media file information
        exiftool               # Image/video metadata
      ];
      
      # Enhanced file type detection
      environment.etc."file/magic.mime".source = "${pkgs.file}/share/misc/magic.mgc";
      
      # Shell functions for enhanced file operations
      environment.shellInit = ''
        # Enhanced file operations
        mkcd() { mkdir -p "$1" && cd "$1"; }
        extract() {
          if [ -f "$1" ]; then
            case "$1" in
              *.tar.bz2)   tar xjf "$1"     ;;
              *.tar.gz)    tar xzf "$1"     ;;
              *.bz2)       bunzip2 "$1"     ;;
              *.rar)       unrar x "$1"     ;;
              *.gz)        gunzip "$1"      ;;
              *.tar)       tar xf "$1"      ;;
              *.tbz2)      tar xjf "$1"     ;;
              *.tgz)       tar xzf "$1"     ;;
              *.zip)       unzip "$1"       ;;
              *.Z)         uncompress "$1"  ;;
              *.7z)        7z x "$1"        ;;
              *)           echo "Don't know how to extract '$1'" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        }
        
        # Quick file preview
        qview() {
          if command -v bat > /dev/null; then
            bat --style=header,grid --color=always "$1"
          else
            cat "$1"
          fi
        }
        
        # Smart ls based on directory size
        smartls() {
          local count=$(ls -1 | wc -l)
          if [ $count -gt 50 ]; then
            ls | head -20
            echo "... and $((count - 20)) more files"
          else
            if command -v eza > /dev/null; then
              eza --icons --git
            else
              ls -la
            fi
          fi
        }
      '';
      
      # Documentation and man pages
      documentation = {
        enable = true;
        man.enable = true;
        info.enable = true;
      };
    }
  ]);
}