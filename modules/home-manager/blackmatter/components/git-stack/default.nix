# modules/home-manager/blackmatter/components/git-stack/default.nix
# Stacked-pull-request workflow tooling (spr / git-spice).
#
# pleme-io adopts commit-per-PR (`spr`) as the default stacked-PR model:
# each commit becomes one GitHub PR; `spr diff` synchronizes the stack;
# reviewers land bottom-up while the operator continues at the top.
# `git-spice` is available as a branch-per-PR fallback for users who
# prefer that model.
#
# Authoritative documentation: stacked-prs skill in blackmatter-pleme.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.git-stack;
in {
  options = {
    blackmatter = {
      components = {
        git-stack = {
          enable = mkEnableOption "stacked-pull-request workflow tooling";

          tool = mkOption {
            type = types.enum [ "spr" "git-spice" ];
            default = "spr";
            description = ''
              Which stacked-PR tool to designate as primary. Both binaries
              can be installed simultaneously via `installBoth`; this option
              determines which set of git aliases and global config is
              written.
            '';
          };

          installBoth = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Install both `spr` and `git-spice` so users can experiment
              between them. The `tool` option still selects which one's
              aliases and global config are active.

              git-spice is exposed as `git-spice` (long name only).
              Upstream's short `gs` binary is dropped to avoid colliding
              with Ghostscript's `gs` in the same pkgs.buildEnv. The
              component's git aliases (`git stack` etc.) dispatch to the
              long name when `tool = "git-spice"`.
            '';
          };

          aliases = mkOption {
            type = types.bool;
            default = true;
            description = ''
              Write `git stack` / `git land` / `git restack` aliases that
              dispatch to the active tool. Disable if you want to invoke
              `spr` / `gs` directly without aliases.
            '';
          };

          spr = {
            branchPrefix = mkOption {
              type = types.str;
              default = "spr";
              description = "Prefix for spr-managed branch names on the remote.";
            };

            createDraftPRs = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Open new PRs as drafts. pleme-io default — matches the
                existing convention of opening drafts and marking
                ready-for-review only when smoke tests are green.
              '';
            };

            deleteMergedBranches = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Auto-cleanup local stack branches once their PR has merged.
                Keeps the local branch list aligned with stack state.
              '';
            };

            noRebase = mkOption {
              type = types.bool;
              default = false;
              description = "Skip automatic rebasing during stack updates.";
            };

            extraConfig = mkOption {
              type = types.attrs;
              default = { };
              description = ''
                Extra keys merged into ~/.spr.yml. Use for repo-host
                overrides (e.g. `githubHost = "github.enterprise.com"`).
              '';
              example = {
                githubHost = "github.com";
                requireApproval = true;
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Install the binaries from nixpkgs.
    #
    # git-spice is exposed as `git-spice` (long name only) — the upstream
    # `gs` short binary collides with Ghostscript's `gs` in pkgs.buildEnv.
    # Renaming via symlinkJoin keeps both tools installable and resolves
    # the conflict at the substrate level rather than asking operators to
    # choose between stacked-PR tooling and ghostscript. Aliases below
    # dispatch to `git-spice ...` for the renamed long-name form.
    (let
      git-spice-renamed = pkgs.symlinkJoin {
        name = "git-spice-bm-${pkgs.git-spice.version}";
        pname = "git-spice-bm";
        version = pkgs.git-spice.version;
        paths = [ pkgs.git-spice ];
        postBuild = ''
          if [ -e $out/bin/gs ]; then
            rm $out/bin/gs
          fi
          ln -s ${pkgs.git-spice}/bin/gs $out/bin/git-spice
        '';
        meta = pkgs.git-spice.meta // {
          description = "${pkgs.git-spice.meta.description or "git-spice"} (binary renamed from gs to git-spice to avoid ghostscript collision)";
        };
      };
    in {
      home.packages = (optional (cfg.tool == "spr" || cfg.installBoth) pkgs.spr)
        ++ (optional (cfg.tool == "git-spice" || cfg.installBoth) git-spice-renamed);
    })

    # Write the per-user spr config (only when spr is active).
    (mkIf (cfg.tool == "spr") {
      home.file.".spr.yml".text = let
        sprConfig = {
          branchPrefix = cfg.spr.branchPrefix;
          createDraftPRs = cfg.spr.createDraftPRs;
          deleteMergedBranches = cfg.spr.deleteMergedBranches;
          noRebase = cfg.spr.noRebase;
        } // cfg.spr.extraConfig;
        # Render as YAML by hand (avoids pulling in pkgs.lib.generators on
        # every component load and keeps the output operator-readable).
        renderValue = v:
          if isBool v then (if v then "true" else "false")
          else if isString v then "\"${v}\""
          else toString v;
        renderLine = name: value: "${name}: ${renderValue value}";
      in concatStringsSep "\n" (mapAttrsToList renderLine sprConfig) + "\n";
    })

    # Git aliases that dispatch to the active tool. Users can still call
    # `spr` / `gs` directly; the aliases are the easy on-ramp.
    #
    # The blackmatter.components.gitconfig component owns ~/.gitconfig
    # directly via home.file. We write our aliases to a separate include
    # file and inject the [include] directive into gitconfig's extraConfig
    # — only when the gitconfig component is also enabled.
    (mkIf cfg.aliases (
      let
        sprAliases = ''
          [alias]
            stack    = !spr diff
            restack  = !spr update
            land     = !spr land
            stackls  = !spr status
        '';
        # git-spice's `gs` binary is renamed to `git-spice` in this
        # component to avoid the Ghostscript collision; aliases dispatch
        # to the long name accordingly.
        spiceAliases = ''
          [alias]
            stack    = !git-spice stack submit
            restack  = !git-spice stack restack
            land     = !git-spice branch land
            stackls  = !git-spice log short
        '';
      in {
        home.file.".config/git/git-stack.gitconfig".text =
          if cfg.tool == "spr" then sprAliases else spiceAliases;

        blackmatter.components.gitconfig.extraConfig = mkIf
          config.blackmatter.components.gitconfig.enable
          ''
            [include]
              path = ~/.config/git/git-stack.gitconfig
          '';
      }
    ))
  ]);
}
