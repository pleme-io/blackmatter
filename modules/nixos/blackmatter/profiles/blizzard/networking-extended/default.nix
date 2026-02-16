# modules/nixos/blackmatter/profiles/blizzard/networking-extended/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.networkingExtended;
  profileCfg = config.blackmatter.profiles.blizzard;
  dnsCfg = config.blackmatter.profiles.blizzard.dns;
in {
  options.blackmatter.profiles.blizzard.networkingExtended = {
    hostName = mkOption {
      type = types.str;
      description = "Hostname for this machine";
    };

    interfaces = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          ipv4Addresses = mkOption {
            type = types.listOf (types.submodule {
              options = {
                address = mkOption {
                  type = types.str;
                  description = "IPv4 address";
                };
                prefixLength = mkOption {
                  type = types.int;
                  description = "Network prefix length";
                };
              };
            });
            default = [];
            description = "Static IPv4 addresses for this interface";
          };
        };
      });
      default = {};
      description = "Network interface configuration";
      example = literalExpression ''
        {
          "enp5s0" = {
            ipv4Addresses = [{
              address = "192.168.50.3";
              prefixLength = 24;
            }];
          };
        }
      '';
    };

    networkManager = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NetworkManager (for laptops/mobile devices)";
      };

      wifi = {
        powersave = mkOption {
          type = types.bool;
          default = false;
          description = "Enable WiFi power saving";
        };
      };
    };

    wireless = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable wireless networking (wpa_supplicant)";
      };

      networks = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            psk = mkOption {
              type = types.str;
              description = "Pre-shared key for network";
            };
            priority = mkOption {
              type = types.int;
              default = 5;
              description = "Network priority (higher is preferred)";
            };
          };
        });
        default = {};
        description = "Wireless network configurations";
      };
    };

    defaultGateway = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          address = mkOption {
            type = types.str;
            description = "Gateway IP address";
          };
          interface = mkOption {
            type = types.str;
            description = "Interface to use for gateway";
          };
        };
      });
      default = null;
      description = "Default gateway configuration";
    };

    nameservers = mkOption {
      type = types.listOf types.str;
      default = ["1.1.1.1" "8.8.8.8"];
      description = "DNS nameserver addresses";
    };

    dhcpcdExtraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra dhcpcd configuration";
    };

    firewall = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      allowPing = mkOption {
        type = types.bool;
        default = true;
        description = "Allow ICMP ping";
      };

      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Trusted network interfaces (bypass firewall)";
      };

      allowedTCPPorts = mkOption {
        type = types.listOf types.int;
        default = [];
        description = "Allowed TCP ports";
      };

      allowedUDPPorts = mkOption {
        type = types.listOf types.int;
        default = [];
        description = "Allowed UDP ports";
      };
    };

    hosts = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = ''
        Additional static hosts file entries.
        These will be merged with network topology hosts if useNetworkTopology is enabled.
      '';
      example = literalExpression ''
        {
          "192.168.50.3" = ["plo.local" "ollama.plo.local"];
        }
      '';
    };

    useNetworkTopology = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use the centralized network topology for /etc/hosts entries.
        When enabled, all nodes and services from blackmatter.networkTopology
        will be automatically added to /etc/hosts.
        Additional entries can still be added via hosts option.
      '';
    };
  };

  config = mkIf profileCfg.enable {
    networking.hostName = cfg.hostName;

    networking.interfaces =
      mapAttrs (name: iface: {
        ipv4.addresses = iface.ipv4Addresses;
      })
      cfg.interfaces;

    # NetworkManager configuration (for laptops/mobile)
    networking.networkmanager = mkIf cfg.networkManager.enable {
      enable = true;
      wifi.powersave = cfg.networkManager.wifi.powersave;
    };

    # wpa_supplicant configuration (for servers/desktops)
    networking.wireless = mkIf cfg.wireless.enable {
      enable = true;
      networks = cfg.wireless.networks;
    };

    networking.defaultGateway = mkIf (cfg.defaultGateway != null) cfg.defaultGateway;

    # Only set nameservers if DNS module is not managing them
    # When dnsmasq or resolved is enabled, DNS module handles nameserver configuration
    networking.nameservers = mkIf (!dnsCfg.dnsmasq.enable && !dnsCfg.resolved.enable) cfg.nameservers;

    networking.dhcpcd.extraConfig = cfg.dhcpcdExtraConfig;

    networking.firewall = {
      enable = cfg.firewall.enable;
      allowPing = cfg.firewall.allowPing;
      trustedInterfaces = cfg.firewall.trustedInterfaces;
      allowedTCPPorts = cfg.firewall.allowedTCPPorts;
      allowedUDPPorts = cfg.firewall.allowedUDPPorts;
    };

    # Merge network topology hosts with custom hosts
    networking.hosts = mkMerge [
      (mkIf cfg.useNetworkTopology config.blackmatter.networkTopology.hostsEntries)
      cfg.hosts
    ];
  };
}
