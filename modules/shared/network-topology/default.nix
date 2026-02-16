# Centralized network topology for quero.local infrastructure
# All nodes, services, and their IP addresses defined in one place
# Imported by both NixOS (blizzard) and Darwin (macos) profiles
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
    # ========== PHYSICAL NODES ==========
    nodes = {
      plo = {
        ipv4 = "192.168.50.3";
        domains = ["plo.quero.local" "plo.local"];
        k8sApiPort = 6443;
      };

      zek = {
        ipv4 = "192.168.50.47";
        domains = ["zek.quero.local" "zek.local"];
        k8sApiPort = 6443;
      };

      rai = {
        ipv4 = "192.168.50.2";
        domains = ["rai.quero.local" "rai.local"];
        k8sApiPort = null;
      };

      router = {
        ipv4 = "192.168.50.1";
        domains = ["router" "router.quero.local"];
        k8sApiPort = null;
      };

      # vfkit VM on cid (Apple Silicon) — dynamic IP from vfkit DHCP
      cid-k3s = {
        ipv4 = "192.168.64.2";
        domains = ["cid-k3s.quero.local" "cid-k3s.local"];
        k8sApiPort = null; # Agent only
      };
    };

    # ========== INFRASTRUCTURE SERVICES ==========
    services = {
      # === Nix Build Infrastructure ===
      "nix-builder" = {
        ipv4 = "192.168.50.100";
        domains = [
          "nix-builder"
          "nix-builder.infrastructure.plo.quero.local"
        ];
        port = 2222;
      };

      "attic-cache-legacy" = {
        ipv4 = "192.168.50.3"; # Legacy cache - kept for backwards compatibility
        domains = [
          "cache.novaskyn-staging.plo.quero.local"
          "cache.staging.novaskyn.com"
        ];
        port = 80;
      };

      "attic-cache" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer - new shared nix-cache
        domains = [
          "cache.plo.quero.local"
        ];
        port = 80;
      };

      # === Storage Services ===
      "minio-plo" = {
        ipv4 = "192.168.50.3";
        domains = [
          "minio.infrastructure.plo.quero.local"
          "minio-console.infrastructure.plo.quero.local"
        ];
        port = 31900;
      };

      "minio-zek" = {
        ipv4 = "192.168.50.47";
        domains = ["minio.infrastructure.zek.quero.local"];
        port = 31900;
      };

      "nextcloud" = {
        ipv4 = "192.168.50.3";
        domains = ["nextcloud.infrastructure.plo.quero.local"];
        port = null;
      };

      # === Container Registries ===
      "registry-plo" = {
        ipv4 = "192.168.50.3";
        domains = ["registry.plo.quero.local"];
        port = 30500;
      };

      "registry-zek" = {
        ipv4 = "192.168.50.47";
        domains = [
          "registry.zek.quero.local"
          "monitoring.zek.quero.local"
        ];
        port = 30500;
      };

      # === Development Tools ===
      "curupira" = {
        ipv4 = "192.168.50.3";
        domains = ["curupira.infrastructure.plo.quero.local"];
        port = null;
      };

      "chrome-debug" = {
        ipv4 = "192.168.50.3";
        domains = ["chrome-debug.infrastructure.plo.quero.local"];
        port = null;
      };

      # === AI Platform ===
      "ollama" = {
        ipv4 = "192.168.50.3";
        domains = [
          "ollama.plo.quero.local"
          "llm.plo.quero.local"
        ];
        port = null;
      };

      "ai-platform" = {
        ipv4 = "192.168.50.3";
        domains = [
          "ai.plo.quero.local"
          "chromadb.plo.quero.local"
          "webui.plo.quero.local"
          "rag.plo.quero.local"
        ];
        port = null;
      };

      # === NovaSkyn Environments ===
      "novaskyn-staging" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = [
          "novaskyn.staging.plo.quero.local"
          "api.novaskyn.staging.plo.quero.local"
          "auth.novaskyn.staging.plo.quero.local"
          "cart.novaskyn.staging.plo.quero.local"
          "email.novaskyn.staging.plo.quero.local"
          "inventory.novaskyn.staging.plo.quero.local"
          "orders.novaskyn.staging.plo.quero.local"
          "payment.novaskyn.staging.plo.quero.local"
          "product-import.novaskyn.staging.plo.quero.local"
          "search.novaskyn.staging.plo.quero.local"
          "notifications.novaskyn.staging.plo.quero.local"
          "shipping.novaskyn.staging.plo.quero.local"
          "suppliers.novaskyn.staging.plo.quero.local"
          "user.novaskyn.staging.plo.quero.local"
          "webhooks.novaskyn.staging.plo.quero.local"
          "analytics.novaskyn.staging.plo.quero.local"
          "customer-support.novaskyn.staging.plo.quero.local"
          "pricing.novaskyn.staging.plo.quero.local"
          "review.novaskyn.staging.plo.quero.local"
          "safety.novaskyn.staging.plo.quero.local"
        ];
        port = null;
      };

      "novaskyn-production" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = ["novaskyn.production.plo.quero.local"];
        port = null;
      };

      "novaskyn-dev" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = ["novaskyn.dev.plo.quero.local"];
        port = null;
      };

      # === Lilitu Environments ===
      "lilitu-staging" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = [
          "lilitu.staging.plo.quero.local"
          "www.lilitu.staging.plo.quero.local"
          "api.lilitu.staging.plo.quero.local"
          "grafana.lilitu.staging.plo.quero.local"
        ];
        port = null;
      };

      # === Observability Services ===
      # Cluster-wide tools - not environment-scoped
      "observability" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = [
          "grafana.plo.quero.local"
          "prometheus.plo.quero.local"
        ];
        port = null;
      };

      # === Mail Testing ===
      "mailpit" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = ["mailpit.plo.quero.local"];
        port = null;
      };

      # === Object Storage ===
      "rustfs" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = [
          "rustfs.plo.quero.local"
          "s3.plo.quero.local"
        ];
        port = null;
      };

      # === Secrets Management ===
      "openbao" = {
        ipv4 = "192.168.50.100"; # Istio LoadBalancer IP
        domains = [
          "openbao.plo.quero.local"
        ];
        port = null;
      };

      # === Legacy RAI Services ===
      "rai-services" = {
        ipv4 = "192.168.50.2";
        domains = [
          "podinfo.rai"
          "harbor.rai"
          "registry.harbor.rai"
          "minio.rai"
          "minio-console.rai"
          "dex.rai"
          "grafana.rai"
          "alertmanager.rai"
          "registry.rai"
          "godin.rai"
          "chat.quero.local"
          "bot.quero.local"
          "backend.quero.local"
          "orchestrator.quero.local"
          "prometheus.quero.local"
          "grafana.quero.local"
          "www.quero.local"
        ];
        port = null;
      };
    };

    # ========== COMPUTED HELPERS ==========
    # These are automatically generated from nodes and services above

    # Generate flat DNS address mappings for nix-darwin
    dnsAddresses = lib.mkMerge [
      # Node domains
      (lib.concatMapAttrs (
          name: node:
            lib.genAttrs node.domains (_: node.ipv4)
        )
        config.blackmatter.networkTopology.nodes)

      # Service domains
      (lib.concatMapAttrs (
          name: service:
            lib.genAttrs service.domains (_: service.ipv4)
        )
        config.blackmatter.networkTopology.services)
    ];

    # Generate dnsmasq mappings for NixOS
    dnsmasqMappings =
      # Node mappings
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
      # Service mappings
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
      # Group domains by IP address
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
      # Remove duplicates from each IP's domain list
      lib.mapAttrs (_: domains: lib.unique domains) domainsByIp;
  };
}
