# modules/home-manager/blackmatter/components/gitconfig/default.nix
# Enhanced git experience with Rust-based tools
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.gitconfig;
in {
  options = {
    blackmatter = {
      components = {
        gitconfig = {
          enable = mkEnableOption "Git configuration";

          user = {
            name = mkOption {
              type = types.str;
              default = "";
              description = "Git user name";
              example = "John Doe";
            };

            email = mkOption {
              type = types.str;
              default = "";
              description = "Git user email";
              example = "john@example.com";
            };
          };

          init = {
            defaultBranch = mkOption {
              type = types.str;
              default = "main";
              description = "Default branch name for new repositories";
            };
          };

          push = {
            default = mkOption {
              type = types.str;
              default = "simple";
              description = "Default push behavior";
            };
          };

          merge = {
            default = mkOption {
              type = types.str;
              default = "merge";
              description = "Default merge strategy";
            };
          };

          core = {
            pager = mkOption {
              type = types.str;
              default = "delta --dark --line-numbers";
              description = "Git pager command";
            };

            editor = mkOption {
              type = types.str;
              default = "nvim";
              description = "Default editor for Git";
            };
          };

          delta = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable delta-specific configuration";
            };

            sideBySide = mkOption {
              type = types.bool;
              default = true;
              description = "Enable side-by-side view in delta";
            };

            nordTheme = mkOption {
              type = types.bool;
              default = true;
              description = "Use Nord color theme for delta";
            };

            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = "Extra delta configuration";
              example = ''
                line-numbers = true
                syntax-theme = Dracula
              '';
            };
          };

          rustTools = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable Rust-based git enhancement tools";
            };

            gitui = mkOption {
              type = types.bool;
              default = true;
              description = "Enable gitui (blazing fast terminal UI for git) - Linux only";
            };

            lazygit = mkOption {
              type = types.bool;
              default = true;
              description = "Enable lazygit (simple terminal UI for git) - Cross-platform";
            };

            gitAbsorb = mkOption {
              type = types.bool;
              default = true;
              description = "Enable git-absorb (automatically absorb staged changes)";
            };

            onefetch = mkOption {
              type = types.bool;
              default = true;
              description = "Enable onefetch (git repository summary)";
            };

            gitCliff = mkOption {
              type = types.bool;
              default = true;
              description = "Enable git-cliff (changelog generator)";
            };

            tokei = mkOption {
              type = types.bool;
              default = true;
              description = "Enable tokei (code statistics)";
            };
          };

          aliases = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable curated git aliases";
            };
          };

          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Extra gitconfig content";
            example = ''
              [pull]
                rebase = false
              [push]
                default = current
            '';
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Core git configuration
    {
      home.file.".gitconfig".text = ''
        [user]
          email = ${cfg.user.email}
          name = ${cfg.user.name}

        [init]
          defaultBranch = ${cfg.init.defaultBranch}

        [push]
          default = ${cfg.push.default}
          autoSetupRemote = true

        [pull]
          rebase = false

        [merge]
          default = ${cfg.merge.default}
          conflictstyle = diff3

        [core]
          pager = ${cfg.core.pager}
          editor = ${cfg.core.editor}
          autocrlf = input

        [fetch]
          prune = true
          prunetagsOnFetch = true

        [rebase]
          autoStash = true
          autoSquash = true

        [diff]
          algorithm = histogram
          colorMoved = default

        ${optionalString cfg.delta.enable ''
        [interactive]
          diffFilter = delta --color-only --features=interactive

        [delta]
          navigate = true
          light = false
          side-by-side = ${if cfg.delta.sideBySide then "true" else "false"}
          line-numbers = true
          features = decorations
          ${optionalString cfg.delta.nordTheme ''
          # Nord color theme - Arctic beauty
          syntax-theme = Nord
          file-style = bold ${"\#"}88C0D0
          file-decoration-style = ${"\#"}88C0D0 ul
          file-added-label = [+]
          file-copied-label = [==]
          file-modified-label = [*]
          file-removed-label = [-]
          file-renamed-label = [->]
          hunk-header-decoration-style = ${"\#"}4C566A box
          hunk-header-file-style = ${"\#"}ECEFF4
          hunk-header-line-number-style = ${"\#"}88C0D0
          hunk-header-style = file line-number syntax
          minus-style = syntax ${"\#"}3B2E30
          minus-non-emph-style = syntax ${"\#"}3B2E30
          minus-emph-style = syntax ${"\#"}6B2E30
          minus-empty-line-marker-style = syntax ${"\#"}3B2E30
          plus-style = syntax ${"\#"}2E3B30
          plus-non-emph-style = syntax ${"\#"}2E3B30
          plus-emph-style = syntax ${"\#"}2E6B30
          plus-empty-line-marker-style = syntax ${"\#"}2E3B30
          line-numbers-minus-style = ${"\#"}BF616A
          line-numbers-plus-style = ${"\#"}A3BE8C
          line-numbers-left-style = ${"\#"}4C566A
          line-numbers-right-style = ${"\#"}4C566A
          line-numbers-zero-style = ${"\#"}4C566A
          blame-palette = ${"\#"}2E3440 ${"\#"}3B4252 ${"\#"}434C5E ${"\#"}4C566A
          merge-conflict-begin-symbol = ⌃
          merge-conflict-end-symbol = ⌄
          merge-conflict-ours-diff-header-style = ${"\#"}EBCB8B bold
          merge-conflict-ours-diff-header-decoration-style = ${"\#"}4C566A box
          merge-conflict-theirs-diff-header-style = ${"\#"}EBCB8B bold
          merge-conflict-theirs-diff-header-decoration-style = ${"\#"}4C566A box
          ''}
          ${cfg.delta.extraConfig}

        [delta "interactive"]
          keep-plus-minus-markers = false

        [delta "decorations"]
          commit-decoration-style = bold yellow box ul
          commit-style = raw
          hunk-header-decoration-style = ${"\#"}4C566A box
        ''}

        ${optionalString cfg.aliases.enable ''
        [alias]
          # Status & Info
          s = status -sb
          st = status
          info = !onefetch

          # Viewing
          l = log --oneline --graph --decorate
          ll = log --graph --pretty=format:'%C(yellow)%h%Creset -%C(cyan)%d%Creset %s %C(green)(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
          lg = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'
          tree = log --graph --oneline --all --decorate

          # Diffs
          d = diff
          ds = diff --staged
          dc = diff --cached
          dt = difftool

          # Branching
          b = branch
          ba = branch -a
          bd = branch -d
          bD = branch -D
          co = checkout
          cob = checkout -b

          # Commits
          c = commit
          ca = commit -a
          cm = commit -m
          cam = commit -am
          amend = commit --amend --no-edit
          fixup = commit --fixup

          # Staging
          a = add
          aa = add --all
          ap = add --patch
          absorb = absorb --and-rebase

          # Pushing/Pulling
          p = push
          pf = push --force-with-lease
          pl = pull

          # Stashing
          ss = stash
          sp = stash pop
          sl = stash list

          # Utilities
          cleanup = !git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d
          undo = reset --soft HEAD^
          unstage = reset HEAD --
          stats = !tokei
          changelog = cliff
          ui = !lazygit
          lg-ui = !lazygit
        ''}

        ${cfg.extraConfig}
      '';
    }

    # Install Rust-based git tools
    (mkIf cfg.rustTools.enable {
      home.packages = with pkgs; [
        delta  # Beautiful diffs (already configured above)
      ]
      ++ optional cfg.rustTools.gitAbsorb git-absorb
      ++ optional cfg.rustTools.onefetch onefetch
      ++ optional cfg.rustTools.gitCliff git-cliff
      ++ optional cfg.rustTools.tokei tokei
      ++ optional cfg.rustTools.lazygit lazygit  # Cross-platform TUI
      # gitui is Linux-only due to compilation issues on macOS
      ++ optionals (cfg.rustTools.gitui && pkgs.stdenv.isLinux) [ gitui ];
    })
  ]);
}
