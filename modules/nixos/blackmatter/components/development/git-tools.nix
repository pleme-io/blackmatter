# Version Control & Git Ecosystem - Ultimate Git Mastery
{ config, lib, pkgs, ... }:
let
  cfg = config.blackmatter.development.gitTools;
  errors = import ../../../../lib/errors.nix { inherit lib; };
in {
  options.blackmatter.development.gitTools = with lib; {
    enable = mkEnableOption "Comprehensive Git and version control tools";
    
    gitTUI = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Git TUI tools";
      };
      
      includeModern = mkOption {
        type = types.bool;
        default = true;
        description = "Include modern Git TUI tools (lazygit, gitui)";
      };
      
      includeClassic = mkOption {
        type = types.bool;
        default = true;
        description = "Include classic Git TUI tools (tig)";
      };
    };
    
    gitEnhancements = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Git enhancement tools";
      };
      
      includeFlow = mkOption {
        type = types.bool;
        default = true;
        description = "Include Git Flow and workflow tools";
      };
      
      includeSecurity = mkOption {
        type = types.bool;
        default = true;
        description = "Include Git security tools (git-crypt, etc.)";
      };
    };
    
    diffTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable advanced diff and merge tools";
      };
      
      includeModern = mkOption {
        type = types.bool;
        default = true;
        description = "Include modern diff tools (delta, diff-so-fancy)";
      };
    };
    
    hostingPlatforms = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GitHub/GitLab/hosting platform tools";
      };
      
      includeGitHub = mkOption {
        type = types.bool;
        default = true;
        description = "Include GitHub CLI tools";
      };
      
      includeGitLab = mkOption {
        type = types.bool;
        default = true;
        description = "Include GitLab CLI tools";
      };
      
      includeOthers = mkOption {
        type = types.bool;
        default = false;
        description = "Include other platform tools (BitBucket, etc.)";
      };
    };
    
    versionControlSystems = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable other version control systems";
      };
    };
  };
  
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base validation
    {
      assertions = [
        {
          assertion = cfg.gitTUI.enable || cfg.gitEnhancements.enable || 
                     cfg.diffTools.enable || cfg.hostingPlatforms.enable;
          message = errors.format.formatError (
            errors.types.configError "At least one Git tools category must be enabled" {
              available = "gitTUI, gitEnhancements, diffTools, hostingPlatforms";
            }
          );
        }
      ];
    }
    
    # Git TUI Tools Collection
    (lib.mkIf cfg.gitTUI.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Modern Git TUI applications
          (lib.optionals cfg.gitTUI.includeModern [
            lazygit                # Simple terminal UI for git commands
            gitui                  # Blazing fast terminal-ui for Git
            git-absorb             # Automatically absorb fixup commits
            git-branchless         # High-velocity, monorepo-scale workflow
            gitoxide              # Rust implementation of Git
          ]) ++
          
          # Classic Git TUI tools
          (lib.optionals cfg.gitTUI.includeClassic [
            tig                    # Text-mode interface for Git
            gitk                   # Git repository browser (X11)
            git-cola               # Git GUI (has CLI mode)
          ]) ++
          
          # Git visualization and exploration
          [
            git-revise            # Efficiently rewrite Git history
            git-interactive-rebase-tool  # Native cross-platform full-featured terminal-based sequence editor
            gitleaks              # SAST tool for detecting secrets in git repos
            git-bug               # Distributed bug tracker for Git
          ]
        );
        
      # Git TUI aliases
      environment.shellAliases = {
        lg = "lazygit";
        gui = "gitui";
        gt = "tig";
        git-log = "tig";
        git-browse = "tig";
        git-tree = "git log --oneline --graph --all";
        git-visual = "gitk --all";
        secrets = "gitleaks detect";
      };
    })
    
    # Git Enhancement Tools
    (lib.mkIf cfg.gitEnhancements.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Core Git enhancements
          [
            git                    # Distributed version control system
            git-extras             # Collection of useful Git scripts
            git-lfs                # Git Large File Storage
            git-subrepo           # Git submodule alternative
            git-subtrac           # Git subtree alternative
          ] ++
          
          # Git Flow and workflow tools
          (lib.optionals cfg.gitEnhancements.includeFlow [
            git-flow               # Git branching model workflow
            git-town               # Generic, high-level Git workflow support
            git-machete           # Discovers and visualizes git repository structure
            git-when-merged       # Find when a commit was merged
          ]) ++
          
          # Git security and encryption
          (lib.optionals cfg.gitEnhancements.includeSecurity [
            git-crypt             # Transparent file encryption in Git
            git-secret            # Store private data inside git repository
            git-remote-gcrypt     # Encrypted Git remotes
            keychain              # SSH key manager
          ]) ++
          
          # Git utilities and helpers
          [
            git-filter-repo       # Versatile tool for rewriting git history
            git-series            # Track changes to a patch series over time
            git-annex             # Manage files without checking content into Git
            pre-commit            # Multi-language pre-commit framework
            commitizen            # Conventional commits helper
          ]
        );
        
      # Git enhancement aliases
      environment.shellAliases = {
        gf = "git flow";
        gflow = "git flow";
        gcrypt = "git-crypt";
        gsecret = "git secret";
        gannex = "git annex";
        gfilter = "git filter-repo";
        glfs = "git lfs";
        gextras = "git extras";
        gmachete = "git machete";
        gwhen = "git when-merged";
        gsubrepo = "git subrepo";
        gpre = "pre-commit";
        gcommit = "cz commit";
      };
    })
    
    # Diff and Merge Tools
    (lib.mkIf cfg.diffTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Modern diff tools
          (lib.optionals cfg.diffTools.includeModern [
            delta                  # Syntax-highlighting pager for git and diff
            diff-so-fancy         # Good-looking diffs with diff-highlight
            difftastic            # Structural diff tool (experimental)
            git-split-diffs       # GitHub-style split diffs for terminal
          ]) ++
          
          # Classic diff and merge tools
          [
            icdiff                # Improved colored diff
            colordiff             # Colorized diff
            wdiff                 # Word-level diff
            cdiff                 # Colored diff with side-by-side view
            meld                  # Visual diff and merge tool
            vimdiff               # Vim-based diff tool
          ] ++
          
          # Merge and conflict resolution
          [
            git-mediate           # Resolve merge conflicts
            git-merge-tool        # Git merge tool helper
            diffutils             # GNU diff utilities
            patch                 # Apply patches
          ]
        );
        
      # Diff and merge aliases
      environment.shellAliases = {
        diff = "delta";
        gdiff = "git diff | delta";
        gdiffs = "git diff --staged | delta";
        gmerge = "git mergetool";
        gconflicts = "git diff --name-only --diff-filter=U";
        icdiff = "icdiff --line-numbers";
        vdiff = "vimdiff";
        mdiff = "meld";
        wdiff = "wdiff -n";
        patch-apply = "patch -p1 <";
      };
    })
    
    # Hosting Platform Tools
    (lib.mkIf cfg.hostingPlatforms.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # GitHub tools
          (lib.optionals cfg.hostingPlatforms.includeGitHub [
            gh                     # Official GitHub CLI
            hub                    # GitHub wrapper for Git
            github-cli             # GitHub CLI alternative
            act                    # Run GitHub Actions locally
          ]) ++
          
          # GitLab tools
          (lib.optionals cfg.hostingPlatforms.includeGitLab [
            glab                   # GitLab CLI
            gitlab-runner         # GitLab CI/CD runner
          ]) ++
          
          # Other platform tools
          (lib.optionals cfg.hostingPlatforms.includeOthers [
            bit                    # Bit CLI for component collaboration
            # sourcehut tools would go here
            # codeberg tools would go here
          ]) ++
          
          # General hosting utilities
          [
            git-remote-hg         # Mercurial remote helper
            git-cinnabar          # Mozilla's git-cinnabar for Mercurial
            git-review            # Code review workflow
          ]
        );
        
      # Platform tools aliases
      environment.shellAliases = lib.mkMerge [
        (lib.mkIf cfg.hostingPlatforms.includeGitHub {
          ghpr = "gh pr";
          ghissue = "gh issue";
          ghrepo = "gh repo";
          ghactions = "gh run";
          ghclone = "gh repo clone";
          ghfork = "gh repo fork";
          ghview = "gh repo view";
          local-actions = "act";
        })
        
        (lib.mkIf cfg.hostingPlatforms.includeGitLab {
          glpr = "glab mr";
          glissue = "glab issue";
          glpipeline = "glab pipeline";
          glclone = "glab repo clone";
          glview = "glab repo view";
        })
        
        {
          greview = "git review";
          git-hub = "hub";
          git-lab = "glab";
        }
      ];
    })
    
    # Other Version Control Systems (Optional)
    (lib.mkIf cfg.versionControlSystems.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] [
          mercurial             # Distributed version control system
          subversion            # Centralized version control system
          cvs                   # Concurrent Versions System
          bazaar                # Distributed version control system
          fossil                # Distributed software configuration management
          darcs                 # Distributed version control system
        ];
        
      # Other VCS aliases
      environment.shellAliases = {
        hg = "mercurial";
        svn = "subversion";
        bzr = "bazaar";
        fossil-clone = "fossil clone";
        darcs-get = "darcs get";
      };
    })
    
    # Integration and Enhancement
    {
      # Git configuration enhancements
      environment.variables = {
        # Better Git defaults
        GIT_PAGER = lib.mkDefault "delta";
        DELTA_PAGER = "less -R";
        
        # Git editor
        GIT_EDITOR = lib.mkDefault "$EDITOR";
      };
      
      # Enhanced Git functions
      environment.shellInit = ''
        # Git workflow functions
        
        # Quick commit with message
        gquick() {
          if [ -z "$1" ]; then
            echo "Usage: gquick <commit-message>"
            return 1
          fi
          git add -A && git commit -m "$1"
        }
        
        # Create and switch to new branch
        gnew() {
          if [ -z "$1" ]; then
            echo "Usage: gnew <branch-name>"
            return 1
          fi
          git checkout -b "$1"
        }
        
        # Safe push with upstream
        gpush() {
          local branch=$(git branch --show-current)
          git push -u origin "$branch"
        }
        
        # Interactive staging
        gstage() {
          git add -p
        }
        
        # Show Git status with shortcuts
        gstatus() {
          git status -sb
        }
        
        # Git log with graph
        glog() {
          local limit="''${1:-10}"
          git log --oneline --graph --decorate -"$limit"
        }
        
        # Show modified files
        gmodified() {
          git ls-files -m
        }
        
        # Show untracked files
        guntracked() {
          git ls-files -o --exclude-standard
        }
        
        # Git blame with line numbers
        gblame() {
          if [ -z "$1" ]; then
            echo "Usage: gblame <file>"
            return 1
          fi
          git blame -b -w "$1"
        }
        
        # Find commits that changed a file
        ghistory() {
          if [ -z "$1" ]; then
            echo "Usage: ghistory <file>"
            return 1
          fi
          git log --follow --patch -- "$1"
        }
        
        # Git worktree helpers
        gworktree() {
          case "$1" in
            add)
              git worktree add "$2" "$3"
              ;;
            list)
              git worktree list
              ;;
            remove)
              git worktree remove "$2"
              ;;
            *)
              echo "Usage: gworktree {add|list|remove} [args...]"
              ;;
          esac
        }
        
        # Cleanup merged branches
        gcleanup() {
          git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
        }
        
        # Show repository info
        grepo() {
          echo "=== Repository Information ==="
          echo "Remote URL: $(git remote get-url origin 2>/dev/null || echo 'No remote')"
          echo "Current branch: $(git branch --show-current)"
          echo "Last commit: $(git log -1 --pretty=format:'%h %s (%cr)')"
          echo "Repository size: $(du -sh .git 2>/dev/null | cut -f1)"
          echo "Tracked files: $(git ls-files | wc -l)"
          echo "Commits: $(git rev-list --all --count)"
          echo "Contributors: $(git shortlog -sn | wc -l)"
        }
      '';
      
      # Standard Git aliases (global)
      environment.shellAliases = lib.mkMerge [
        {
          # Basic Git aliases
          g = "git";
          ga = "git add";
          gaa = "git add -A";
          gap = "git add -p";
          gb = "git branch";
          gba = "git branch -a";
          gbd = "git branch -d";
          gc = "git commit";
          gcm = "git commit -m";
          gca = "git commit --amend";
          gco = "git checkout";
          gcp = "git cherry-pick";
          gd = "git diff";
          gds = "git diff --staged";
          gf = "git fetch";
          gl = "git pull";
          gp = "git push";
          gr = "git rebase";
          gri = "git rebase -i";
          gs = "git status";
          gss = "git status -s";
          gt = "git tag";
          gw = "git worktree";
          
          # Logging
          glog = "git log --oneline --graph --decorate";
          gloga = "git log --oneline --graph --decorate --all";
          glogp = "git log --patch";
          
          # Stashing
          gsta = "git stash";
          gstaa = "git stash apply";
          gstap = "git stash pop";
          gstal = "git stash list";
          gstad = "git stash drop";
          
          # Remote operations
          gfa = "git fetch --all";
          gfo = "git fetch origin";
          grao = "git remote add origin";
          grso = "git remote set-url origin";
          grv = "git remote -v";
        }
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