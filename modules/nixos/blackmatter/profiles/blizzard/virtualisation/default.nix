# modules/nixos/blackmatter/profiles/blizzard/virtualisation/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.virtualisation;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.virtualisation = {
    libvirtd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable libvirtd for virtual machines";
      };
    };

    docker = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Docker";
      };

      enableOnBoot = mkOption {
        type = types.bool;
        default = true;
        description = "Start Docker daemon on boot";
      };

      insecureRegistries = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of insecure Docker registries";
        example = ["registry.harbor.local" "harbor.local:80"];
      };
    };

    podman = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Podman";
      };
    };
  };

  config = mkIf profileCfg.enable (mkMerge [
    # Base virtualization config (all variants)
    {
      virtualisation.libvirtd.enable = cfg.libvirtd.enable;

      virtualisation.podman = mkIf cfg.podman.enable {
        enable = true;
        dockerSocket.enable = false;
        defaultNetwork.settings.dns_enabled = false;
      };

      virtualisation.docker = mkIf cfg.docker.enable {
        enable = true;
        enableOnBoot = cfg.docker.enableOnBoot;
        rootless = {
          setSocketVariable = false;
          enable = false;
        };
        daemon.settings = mkIf (cfg.docker.insecureRegistries != []) {
          insecure-registries = cfg.docker.insecureRegistries;
        };
      };
    }

    # K3s-optimized container runtime (headless-dev, server, and agent variants)
    (mkIf (cfg.docker.enable && (profileCfg.variant == "headless-dev" || profileCfg.variant == "server" || profileCfg.variant == "agent")) {
      virtualisation.docker.daemon.settings = {
        # ========== STORAGE DRIVER ==========
        # overlay2 is fastest and most production-ready
        storage-driver = "overlay2";

        # ========== LOGGING ==========
        # JSON file driver with rotation to prevent disk fill
        log-driver = "json-file";
        log-opts = {
          max-size = "10m";
          max-file = "3";
          compress = "true";
        };

        # ========== RESOURCE LIMITS ==========
        # Allow containers to use all available resources
        default-ulimits = {
          nofile = {
            Name = "nofile";
            Hard = 1048576;
            Soft = 1048576;
          };
          nproc = {
            Name = "nproc";
            Hard = -1;  # Unlimited
            Soft = -1;
          };
        };

        # ========== NETWORKING ==========
        # Optimize for container networking
        "userland-proxy" = false;  # Use iptables directly for better performance
        "live-restore" = true;  # Keep containers running during daemon restart
        "max-concurrent-downloads" = 10;  # Faster image pulls
        "max-concurrent-uploads" = 10;

        # ========== RUNTIME ==========
        # containerd for better k3s integration
        "default-runtime" = "runc";

        # ========== REGISTRY ==========
        # Mirror and caching
        "registry-mirrors" = [];  # Add your registry mirrors here

        # ========== PERFORMANCE ==========
        # Improve container startup and runtime performance
        "icc" = true;  # Inter-container communication
        "ip-forward" = true;  # Required for container networking
        "iptables" = true;  # Let Docker manage iptables

        # ========== FEATURES ==========
        "experimental" = false;  # Disable experimental features in production
        "metrics-addr" = "127.0.0.1:9323";  # Prometheus metrics

        # ========== SECURITY ==========
        "no-new-privileges" = false;  # Allow privilege escalation when needed

        # ========== DATA ROOT ==========
        # Ensure data is on fast storage (SSD/NVMe)
        data-root = "/var/lib/docker";
      };

      # ========== CONTAINERD OPTIMIZATIONS ==========
      virtualisation.containerd = {
        enable = true;
        settings = {
          version = 2;

          # ========== GRPC ==========
          grpc = {
            max_recv_message_size = 16777216;  # 16MB
            max_send_message_size = 16777216;
          };

          # ========== PLUGINS ==========
          plugins."io.containerd.grpc.v1.cri" = {
            # Enable CNI
            cni = {
              bin_dir = "/opt/cni/bin";
              conf_dir = "/etc/cni/net.d";
            };

            # Container runtime settings
            containerd = {
              default_runtime_name = lib.mkDefault "runc";  # Can be overridden by gpu module for nvidia

              runtimes.runc = {
                runtime_type = "io.containerd.runc.v2";
                options = {
                  SystemdCgroup = true;  # Use systemd for cgroup management
                  BinaryName = "runc";
                };
              };

              # Snapshotter for fast image layers
              snapshotter = "overlayfs";
            };

            # Registry configuration
            registry = {
              config_path = "/etc/containerd/certs.d";
            };

            # Image pulling
            max_concurrent_downloads = 10;

            # Streaming
            stream_server_address = "127.0.0.1";
            stream_server_port = "0";
            enable_tls_streaming = false;
          };

          # ========== METRICS ==========
          metrics = {
            address = "127.0.0.1:1338";
          };

          # ========== TIMEOUTS ==========
          timeouts = {
            "io.containerd.timeout.shim.cleanup" = "5s";
            "io.containerd.timeout.shim.load" = "5s";
            "io.containerd.timeout.shim.shutdown" = "3s";
            "io.containerd.timeout.task.state" = "2s";
          };
        };
      };
    })
  ]);
}
