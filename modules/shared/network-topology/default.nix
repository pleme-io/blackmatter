# Network topology option schema and computed helpers
# Defines the structure for nodes, services, and DNS mappings
# Actual values (IPs, domains) are set per-deployment in the consumer repo
{
  config,
  lib,
  ...
}: {
  options.blackmatter.networkTopology = {
    nodes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address of the node";
          };
          domains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Domain names for this node";
          };
          k8sApiPort = lib.mkOption {
            type = lib.types.nullOr lib.types.port;
            default = null;
            description = "Kubernetes API server port (if running k3s)";
          };
        };
      });
      default = {};
      description = "Network nodes in the infrastructure";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          ipv4 = lib.mkOption {
            type = lib.types.str;
            description = "IPv4 address of the service";
          };
          domains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Domain names for this service";
          };
          port = lib.mkOption {
            type = lib.types.nullOr lib.types.port;
            default = null;
            description = "Service port";
          };
        };
      });
      default = {};
      description = "Infrastructure services and their endpoints";
    };

    # Helper function to generate DNS address mappings
    # Returns attrset of { "domain.name" = "ip.address"; }
    dnsAddresses = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      description = "Computed DNS address mappings for all nodes and services";
    };

    # Helper function to generate dnsmasq domain mappings
    # Returns list of { domain = "/domain.name"; address = "ip.address"; }
    dnsmasqMappings = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.str);
      readOnly = true;
      description = "Computed dnsmasq domain mappings for NixOS nodes";
    };

    # Helper function to generate /etc/hosts entries
    # Returns attrset of { "ip.address" = [ "domain1" "domain2" ]; }
    hostsEntries = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      readOnly = true;
      description = "Computed /etc/hosts entries for all nodes";
    };
  };

  config.blackmatter.networkTopology = {
    # ========== COMPUTED HELPERS ==========
    # Automatically generated from nodes and services set by the consumer

    # Generate flat DNS address mappings for nix-darwin
    dnsAddresses = lib.mkMerge [
      (lib.concatMapAttrs (
          name: node:
            lib.genAttrs node.domains (_: node.ipv4)
        )
        config.blackmatter.networkTopology.nodes)
      (lib.concatMapAttrs (
          name: service:
            lib.genAttrs service.domains (_: service.ipv4)
        )
        config.blackmatter.networkTopology.services)
    ];

    # Generate dnsmasq mappings for NixOS
    dnsmasqMappings =
      (lib.flatten (lib.mapAttrsToList (
          name: node:
            map (domain: {
              domain = "/${domain}";
              address = node.ipv4;
            })
            node.domains
        )
        config.blackmatter.networkTopology.nodes))
      ++
      (lib.flatten (lib.mapAttrsToList (
          name: service:
            map (domain: {
              domain = "/${domain}";
              address = service.ipv4;
            })
            service.domains
        )
        config.blackmatter.networkTopology.services));

    # Generate /etc/hosts entries
    hostsEntries = let
      domainsByIp =
        lib.foldl' (
          acc: item:
            acc
            // {
              ${item.ipv4} = (acc.${item.ipv4} or []) ++ item.domains;
            }
        ) {} (
          (lib.attrValues config.blackmatter.networkTopology.nodes)
          ++ (lib.attrValues config.blackmatter.networkTopology.services)
        );
    in
      lib.mapAttrs (_: domains: lib.unique domains) domainsByIp;
  };
}
