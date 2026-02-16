# modules/home-manager/blackmatter/components/ssh-aliases/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.sshAliases;

  # Helper to create SSH alias
  mkSshAlias = host: user: domain: "ssh ${user}@${host}.${domain}";
in {
  options = {
    blackmatter = {
      components = {
        sshAliases = {
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
                  description = "List of domains to create aliases for (e.g., quero.local, local)";
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
            example = {
              plo = {
                user = "admin";
                domains = ["quero.local" "local"];
                primaryDomain = "quero.local";
              };
            };
          };

          extraAliases = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Additional custom SSH aliases";
            example = {
              prod-server = "ssh admin@production.example.com";
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    programs.zsh.shellAliases = mkMerge [
      # Generate aliases for configured hosts
      (mkMerge (mapAttrsToList (hostname: hostCfg:
        # Create primary alias (e.g., ssh-plo)
        {
          "ssh-${hostname}" = mkSshAlias hostname hostCfg.user hostCfg.primaryDomain;
        }
        //
        # Create domain-specific aliases (e.g., ssh-plo-mdns for .local)
        (listToAttrs (map (domain:
          nameValuePair
            "ssh-${hostname}-${if domain == "local" then "mdns" else builtins.replaceStrings ["."] ["-"] domain}"
            (mkSshAlias hostname hostCfg.user domain)
        ) hostCfg.domains))
      ) cfg.hosts))

      # Extra custom aliases
      cfg.extraAliases
    ];
  };
}
