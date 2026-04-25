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

    quiet = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Suppress non-error chatter from the ssh client — sets
        `LogLevel ERROR` at the wildcard `Host *` scope. Hides messages
        like "Warning: Permanently added '<host>' (ED25519) to the
        list of known hosts." that fire on every TOFU connection,
        plus other informational notices that distract from real
        failures. Defaults to true on every fleet workstation so
        `ssh <peer>` lands at a clean prompt with zero pre-shell
        chatter; flip to false on a node where you want full ssh
        diagnostics back.
      '';
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
        description = "List of hosts accessible via Cloudflare Tunnel (will be suffixed with domainSuffix)";
      };

      domainSuffix = mkOption {
        type = types.str;
        default = "";
        description = "Domain suffix for Cloudflare Tunnel hosts (e.g., 'example.com')";
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

      # UseKeychain is an Apple-fork-only OpenSSH option. Portable OpenSSH
      # (which we ship via Nix on both Darwin and Linux) treats it as a
      # hard parse error. IgnoreUnknown only suppresses subsequent unknown
      # options, so it MUST appear at file-global scope before any Host
      # block that may emit UseKeychain. home-manager renders
      # extraOptionOverrides at the very top of ~/.ssh/config (above all
      # match/host blocks), making it the only ordering-safe placement.
      # On Linux this is a no-op — neither blackmatter nor any node
      # profile emits UseKeychain there.
      extraOptionOverrides = mkIf pkgs.stdenv.isDarwin {
        IgnoreUnknown = "UseKeychain";
      };

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
                # Propagate terminal type for Ghostty/modern terminals
                SendEnv = "TERM COLORTERM TERM_PROGRAM";
              }
              (mkIf cfg.disableHostKeyChecking {
                StrictHostKeyChecking = "no";
              })
              (mkIf cfg.useNullKnownHosts {
                UserKnownHostsFile = "/dev/null";
              })
              (mkIf cfg.quiet {
                LogLevel = "ERROR";
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
        (mkIf cfg.cloudflareTunnel.enable (mkMerge (map (host: let
          fqdn = if cfg.cloudflareTunnel.domainSuffix != ""
            then "${host}.${cfg.cloudflareTunnel.domainSuffix}"
            else host;
        in {
          "${fqdn}" = {
            hostname = fqdn;
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
