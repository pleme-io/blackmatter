# modules/home-manager/blackmatter/components/ssh-aliases/default.nix
# Generates ~/.config/shell/local.d/ssh-aliases.zsh sourced by blackmatter-shell
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.sshAliases;

  mkSshAlias = host: user: domain: "ssh ${user}@${host}.${domain}";

  # Build attrset of name → command for all configured hosts
  hostAliases = foldl' recursiveUpdate {}
    (mapAttrsToList (hostname: hostCfg:
      { "ssh-${hostname}" = mkSshAlias hostname hostCfg.user hostCfg.primaryDomain; }
      //
      listToAttrs (map (domain:
        nameValuePair
          "ssh-${hostname}-${if domain == "local" then "mdns" else builtins.replaceStrings ["."] ["-"] domain}"
          (mkSshAlias hostname hostCfg.user domain)
      ) hostCfg.domains)
    ) cfg.hosts);

  allAliases = hostAliases // cfg.extraAliases;

  aliasContent = concatStringsSep "\n"
    (mapAttrsToList (name: value: "alias ${name}='${value}'") allAliases) + "\n";
in {
  options.blackmatter.components.sshAliases = {
    enable = mkEnableOption "SSH aliases for infrastructure hosts";

    hosts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          user = mkOption {
            type = types.str;
            description = "SSH user for this host";
            example = "admin";
          };
          domains = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Domains to create aliases for (e.g. quero.local, local)";
            example = ["quero.local" "local"];
          };
          primaryDomain = mkOption {
            type = types.str;
            description = "Primary domain for the default alias";
            example = "quero.local";
          };
        };
      });
      default = {};
      description = "SSH host configurations";
    };

    extraAliases = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional custom SSH aliases (name → command)";
      example = { prod = "ssh admin@production.example.com"; };
    };
  };

  config = mkIf (cfg.enable && allAliases != {}) {
    # Write aliases to local.d — picked up by blackmatter-shell's local.d/*.zsh loop
    xdg.configFile."shell/local.d/ssh-aliases.zsh".text = aliasContent;
  };
}
