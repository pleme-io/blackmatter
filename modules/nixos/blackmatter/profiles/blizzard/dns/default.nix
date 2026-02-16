# modules/nixos/blackmatter/profiles/blizzard/dns/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.dns;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.dns = {
    dnsmasq = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable dnsmasq for local DNS";
      };

      useNetworkTopology = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Use the centralized network topology for DNS mappings.
          When enabled, all nodes and services from blackmatter.networkTopology
          will be automatically configured in dnsmasq.
          Additional mappings can still be added via domainMappings option.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 53;
        description = "DNS port to listen on";
      };

      listenAddresses = mkOption {
        type = types.listOf types.str;
        default = ["127.0.0.1"];
        description = "IP addresses to listen on";
      };

      upstreamServers = mkOption {
        type = types.listOf types.str;
        default = ["1.1.1.1" "8.8.8.8"];
        description = "Upstream DNS servers";
      };

      enableFallbackNameservers = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable fallback nameservers via resolvconf.
          If dnsmasq fails to start, system will fall back to upstream servers.
          This prevents complete network outage during dnsmasq failures.
        '';
      };

      cacheSize = mkOption {
        type = types.int;
        default = 1000;
        description = "DNS cache size";
      };

      domainMappings = mkOption {
        type = types.listOf (types.submodule {
          options = {
            domain = mkOption {
              type = types.str;
              description = "Domain name to map";
            };
            address = mkOption {
              type = types.str;
              description = "IP address to resolve to";
            };
          };
        });
        default = [];
        description = ''
          Additional domain to IP address mappings.
          These will be merged with network topology mappings if useNetworkTopology is true.
        '';
        example = literalExpression ''
          [
            {
              domain = "/plo.quero.local";
              address = "192.168.50.3";
            }
            {
              domain = "/api.staging.example.com";
              address = "192.168.50.100";
            }
          ]
        '';
      };

      extraSettings = mkOption {
        type = types.attrsOf types.unspecified;
        default = {};
        description = "Extra dnsmasq settings";
      };

      logQueries = mkOption {
        type = types.bool;
        default = false;
        description = "Log DNS queries";
      };
    };

    resolved = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable systemd-resolved";
      };

      dnssec = mkOption {
        type = types.bool;
        default = false;
        description = "Enable DNSSEC validation";
      };

      cache = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DNS caching";
      };
    };

    useHostResolvConf = mkOption {
      type = types.bool;
      default = false;
      description = "Use host's resolv.conf";
    };

    localNameservers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Local nameservers (typically 127.0.0.1 when using dnsmasq)";
    };
  };

  config = mkIf profileCfg.enable (mkMerge [
    # Dnsmasq configuration
    (mkIf cfg.dnsmasq.enable {
      services.dnsmasq = {
        enable = true;
        # Disable automatic nameserver configuration - we manage it manually below
        resolveLocalQueries = false;
        settings = mkMerge [
          {
            port = cfg.dnsmasq.port;
            domain-needed = true;
            bogus-priv = true;
            no-resolv = true;
            neg-ttl = 3600;
            dns-forward-max = 250;
            no-poll = true;
            listen-address = cfg.dnsmasq.listenAddresses;
            bind-interfaces = true;
            server = cfg.dnsmasq.upstreamServers;
            cache-size = cfg.dnsmasq.cacheSize;
            log-queries = cfg.dnsmasq.logQueries;
            log-facility = if cfg.dnsmasq.logQueries then "/var/log/dnsmasq.log" else "/dev/null";

            address = map (mapping: "${mapping.domain}/${mapping.address}") (
              # Merge network topology mappings with custom mappings
              (if cfg.dnsmasq.useNetworkTopology
               then config.blackmatter.networkTopology.dnsmasqMappings
               else []) ++ cfg.dnsmasq.domainMappings
            );
          }
          cfg.dnsmasq.extraSettings
        ];
      };

      networking = {
        useHostResolvConf = cfg.useHostResolvConf;
        nameservers = mkIf (cfg.localNameservers != []) cfg.localNameservers;

        # Configure fallback nameservers via resolvconf
        # This ensures DNS works even if dnsmasq fails during rebuild
        resolvconf = mkIf cfg.dnsmasq.enableFallbackNameservers {
          enable = true;
          extraConfig = ''
            # Fallback to upstream DNS if dnsmasq fails
            name_servers="${concatStringsSep " " (cfg.localNameservers ++ cfg.dnsmasq.upstreamServers)}"
          '';
        };
      };

      services.resolved.enable = cfg.resolved.enable;
    })

    # Systemd-resolved configuration
    (mkIf cfg.resolved.enable {
      services.resolved = {
        enable = true;
        dnssec = if cfg.resolved.dnssec then "true" else "false";
        fallbackDns = cfg.localNameservers;
      };

      # Configure DNS for resolved
      networking.nameservers = mkIf (cfg.localNameservers != []) cfg.localNameservers;
    })

    # Disable resolved when using dnsmasq
    (mkIf (cfg.dnsmasq.enable && !cfg.resolved.enable) {
      services.resolved.enable = false;
    })
  ]);
}
