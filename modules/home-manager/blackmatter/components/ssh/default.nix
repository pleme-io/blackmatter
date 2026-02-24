# modules/home-manager/blackmatter/components/ssh/default.nix
# SSH Client Configuration - Secure, performant, with nix-builder support
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.ssh;
in {
  options.blackmatter.components.ssh = {
    enable = mkEnableOption "SSH client configuration with performance optimizations";

    disableHostKeyChecking = mkOption {
      type = types.bool;
      default = true;
      description = "Disable host key verification globally (StrictHostKeyChecking no)";
    };

    useNullKnownHosts = mkOption {
      type = types.bool;
      default = true;
      description = "Use /dev/null for known hosts file (never save host keys)";
    };

    nixBuilder = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH configuration for nix-builder";
      };

      hostname = mkOption {
        type = types.str;
        default = "nix-builder";
        description = "SSH hostname for nix-builder";
      };

      fqdn = mkOption {
        type = types.str;
        default = "";
        description = "Fully qualified domain name for nix-builder";
      };

      port = mkOption {
        type = types.int;
        default = 2222;
        description = "SSH port for nix-builder";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "SSH user for nix-builder";
      };

      identityFile = mkOption {
        type = types.str;
        default = "~/.ssh/nix_builder_ed25519";
        description = "SSH identity file for nix-builder";
      };
    };

    performance = {
      enableCompression = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH compression for better performance over slow links";
      };

      enableControlMaster = mkOption {
        type = types.bool;
        default = true;
        description = "Enable SSH connection multiplexing for faster reconnections";
      };

      controlPersist = mkOption {
        type = types.str;
        default = "10m";
        description = "How long to keep control master connections alive";
      };
    };

    extraHosts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          hostname = mkOption {
            type = types.str;
            description = "Actual hostname or IP address";
          };

          port = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "SSH port (default: 22)";
          };

          user = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "SSH user";
          };

          identityFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "SSH identity file";
          };

          disableHostKeyChecking = mkOption {
            type = types.bool;
            default = cfg.disableHostKeyChecking;
            description = "Disable host key checking for this host";
          };

          proxyCommand = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "ProxyCommand for tunneling (e.g., cloudflared access ssh)";
            example = "cloudflared access ssh --hostname %h";
          };

          extraOptions = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Additional SSH options for this host";
          };
        };
      });
      default = {};
      description = "Additional SSH host configurations";
      example = {
        "myserver" = {
          hostname = "192.168.1.100";
          port = 22;
          user = "admin";
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };

    cloudflareTunnel = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Cloudflare Tunnel SSH hosts";
      };

      user = mkOption {
        type = types.str;
        default = "";
        description = "Default SSH user for Cloudflare Tunnel hosts";
      };

      hosts = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of hosts accessible via Cloudflare Tunnel (will be suffixed with .novaskyn.com)";
      };
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra SSH client configuration";
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      extraConfig = cfg.extraConfig;

      matchBlocks = mkMerge [
        # Global defaults via wildcard match
        {
          "*" = {
            extraOptions = mkMerge [
              {
                ServerAliveInterval = "60";
                ServerAliveCountMax = "3";
                TCPKeepAlive = "yes";
                HashKnownHosts = "yes";
                IdentitiesOnly = "yes";
              }
              (mkIf cfg.disableHostKeyChecking {
                StrictHostKeyChecking = "no";
              })
              (mkIf cfg.useNullKnownHosts {
                UserKnownHostsFile = "/dev/null";
              })
              (mkIf cfg.performance.enableCompression {
                Compression = "yes";
              })
              (mkIf cfg.performance.enableControlMaster {
                ControlMaster = "auto";
                ControlPath = if pkgs.stdenv.isDarwin then "/tmp/ssh-control-%r@%h:%p" else "/run/user/%i/ssh-control-%r@%h:%p";
                ControlPersist = cfg.performance.controlPersist;
              })
            ];
          };
        }

        # Nix builder host
        (mkIf cfg.nixBuilder.enable {
          "${cfg.nixBuilder.hostname}" = {
            hostname = cfg.nixBuilder.fqdn;
            port = cfg.nixBuilder.port;
            user = cfg.nixBuilder.user;
            identityFile = [cfg.nixBuilder.identityFile];
            extraOptions = {
              StrictHostKeyChecking = "no";
              UserKnownHostsFile = "/dev/null";
              LogLevel = "ERROR"; # Suppress known_hosts warnings
            };
          };
        })

        # Extra hosts
        (mkMerge (mapAttrsToList (hostAlias: hostCfg: {
          "${hostAlias}" = mkMerge [
            {
              hostname = hostCfg.hostname;
            }
            (mkIf (hostCfg.port != null) {
              port = hostCfg.port;
            })
            (mkIf (hostCfg.user != null) {
              user = hostCfg.user;
            })
            (mkIf (hostCfg.identityFile != null) {
              identityFile = [hostCfg.identityFile];
            })
            (mkIf (hostCfg.proxyCommand != null) {
              proxyCommand = hostCfg.proxyCommand;
            })
            (mkIf hostCfg.disableHostKeyChecking {
              extraOptions = {
                StrictHostKeyChecking = "no";
                UserKnownHostsFile = "/dev/null";
                LogLevel = "ERROR";
              };
            })
            {
              extraOptions = hostCfg.extraOptions;
            }
          ];
        }) cfg.extraHosts))

        # Cloudflare Tunnel SSH hosts
        (mkIf cfg.cloudflareTunnel.enable (mkMerge (map (host: {
          "${host}.novaskyn.com" = {
            hostname = "${host}.novaskyn.com";
            user = cfg.cloudflareTunnel.user;
            proxyCommand = "${pkgs.cloudflared}/bin/cloudflared access ssh --hostname %h";
            extraOptions = {
              StrictHostKeyChecking = "no";
              UserKnownHostsFile = "/dev/null";
              LogLevel = "ERROR";
            };
          };
        }) cfg.cloudflareTunnel.hosts)))
      ];
    };

    # Install cloudflared when tunnel SSH is enabled
    home.packages = mkIf cfg.cloudflareTunnel.enable [
      pkgs.cloudflared
    ];
  };
}
