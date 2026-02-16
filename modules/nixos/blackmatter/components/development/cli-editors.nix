# Core Development Environment - CLI/TUI Editors and Tools
{ config, lib, pkgs, ... }:
let
  cfg = config.blackmatter.development.cliEditors;
  errors = import ../../../../lib/errors.nix { inherit lib; };
in {
  options.blackmatter.development.cliEditors = with lib; {
    enable = mkEnableOption "Core CLI/TUI development environment";
    
    textEditors = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable comprehensive text editor collection";
      };
      
      includeAdvanced = mkOption {
        type = types.bool;
        default = true;
        description = "Include advanced/experimental editors (helix, kakoune, etc.)";
      };
      
      includeClassic = mkOption {
        type = types.bool;
        default = true;
        description = "Include classic editors (vim, emacs, nano)";
      };
    };
    
    terminalMultiplexers = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable terminal multiplexers";
      };
      
      includeModern = mkOption {
        type = types.bool;
        default = true;
        description = "Include modern multiplexers (zellij, byobu)";
      };
    };
    
    sessionManagement = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable session management tools";
      };
    };
    
    ides = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable terminal-based IDEs (lighter option)";
      };
    };
  };
  
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base validation
    {
      assertions = [
        {
          assertion = cfg.textEditors.enable || cfg.terminalMultiplexers.enable || cfg.sessionManagement.enable || cfg.ides.enable;
          message = errors.format.formatError (
            errors.types.configError "At least one category must be enabled" {
              available = "textEditors, terminalMultiplexers, sessionManagement, ides";
            }
          );
        }
      ];
    }
    
    # Text Editors Collection
    (lib.mkIf cfg.textEditors.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Classic editors (always reliable)
          (lib.optionals cfg.textEditors.includeClassic [
            vim                    # The classic modal editor
            neovim                 # Modern vim fork with Lua support
            emacs                  # The extensible, customizable editor
            nano                   # Simple, user-friendly editor
            micro                  # Modern terminal-based text editor
          ]) ++
          
          # Advanced/Modern editors
          (lib.optionals cfg.textEditors.includeAdvanced [
            helix                  # Post-modern modal text editor
            kakoune               # Modal editor with multiple selections
            vis                   # Vi-like editor with structural regex
            amp                   # Modern text editor inspired by Xi
          ]) ++
          
          # Additional utility editors
          [
            ed                    # Line-oriented text editor (POSIX)
            joe                   # WordStar-like editor
            jed                   # Emacs-like editor with less features
          ]
        );
        
      # Enhanced vim configuration
      programs.vim = {
        enable = true;
        defaultEditor = lib.mkDefault false;  # Let user choose
      };
      
      # Neovim enhanced setup
      programs.neovim = {
        enable = true;
        defaultEditor = lib.mkDefault true;
        viAlias = true;
        vimAlias = true;
      };
    })
    
    # Terminal Multiplexers
    (lib.mkIf cfg.terminalMultiplexers.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] ([
          tmux                   # The classic terminal multiplexer
          screen                 # Original terminal multiplexer
        ] ++ 
        (lib.optionals cfg.terminalMultiplexers.includeModern [
          zellij                 # Modern terminal workspace
          byobu                  # Enhanced tmux/screen wrapper
          abduco                 # Lightweight session management
          dtach                  # Simple program detacher
        ]));
        
      # Enhanced tmux configuration
      programs.tmux = {
        enable = true;
        
        extraConfig = ''
          # Enhanced tmux configuration for power users
          
          # Key mode and prefix
          set-window-option -g mode-keys vi
          set-option -g prefix C-a
          unbind-key C-b
          bind-key C-a send-prefix
          
          # Escape time
          set-option -sg escape-time 0
          
          # History and terminal
          set-option -g history-limit 50000
          set-option -g default-terminal "screen-256color"
          
          # Better defaults
          set -g mouse on
          set -g renumber-windows on
          set -g base-index 1
          set -g pane-base-index 1
          set -g automatic-rename on
          set -g set-titles on
          
          # Status bar
          set -g status-position bottom
          set -g status-justify left
          set -g status-style 'bg=colour234 fg=colour137'
          set -g status-left ""
          set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
          set -g status-right-length 50
          set -g status-left-length 20
          
          # Window status
          setw -g window-status-current-style 'fg=colour1 bg=colour19 bold'
          setw -g window-status-current-format ' #I#[fg=colour249]:#[fg=colour255]#W#[fg=colour249]#F '
          setw -g window-status-style 'fg=colour9 bg=colour18'
          setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '
          
          # Pane borders
          set -g pane-border-style 'fg=colour238 bg=colour235'
          set -g pane-active-border-style 'bg=colour236 fg=colour51'
          
          # Key bindings
          bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
          bind | split-window -h
          bind - split-window -v
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R
          
          # Copy mode
          bind-key -T copy-mode-vi 'v' send -X begin-selection
          bind-key -T copy-mode-vi 'y' send -X copy-selection-and-cancel
          
          # Plugins support (for future enhancement)
          set -g @plugin 'tmux-plugins/tpm'
          set -g @plugin 'tmux-plugins/tmux-sensible'
          set -g @plugin 'tmux-plugins/tmux-yank'
          set -g @plugin 'tmux-plugins/tmux-resurrect'
          set -g @plugin 'tmux-plugins/tmux-continuum'
          
          # Initialize TMUX plugin manager (keep this at the very bottom)
          run '~/.tmux/plugins/tpm/tpm'
        '';
      };
    })
    
    # Session Management Tools
    (lib.mkIf cfg.sessionManagement.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] [
          tmuxp                  # Tmux session manager
          tmuxinator            # Tmux project management
          teamocil              # Simple tmux session management
          tmate                 # Instant terminal sharing
        ];
    })
    
    # Terminal-based IDEs (lighter option)
    (lib.mkIf cfg.ides.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] [
          lite-xl               # Lightweight text editor/IDE
          textadept             # Fast, minimalist editor
          # Note: Some IDEs might not be available or might be GUI-only
        ];
    })
    
    # Environment enhancements
    {
      # Ensure proper EDITOR variables
      environment.variables = {
        EDITOR = lib.mkIf cfg.textEditors.enable (
          if config.programs.neovim.enable then "nvim"
          else if cfg.textEditors.includeClassic then "vim"
          else "nano"
        );
        
        # Tmux-related environment
        TMUX_TMPDIR = lib.mkIf cfg.terminalMultiplexers.enable "/tmp";
      };
      
      # Shell aliases for convenience
      environment.shellAliases = lib.mkMerge [
        (lib.mkIf cfg.textEditors.enable {
          vi = "nvim";
          vim = "nvim";
          edit = "$EDITOR";
        })
        
        (lib.mkIf cfg.terminalMultiplexers.enable {
          tm = "tmux";
          tma = "tmux attach-session -t";
          tmn = "tmux new-session -s";
          tml = "tmux list-sessions";
        })
      ];
      
      # Documentation and man pages
      documentation = {
        enable = true;
        man.enable = true;
        info.enable = true;
      };
    }
  ]);
}