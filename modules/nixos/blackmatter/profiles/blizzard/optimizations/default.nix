# modules/nixos/blackmatter/profiles/blizzard/optimizations/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.optimizations;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.optimizations = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable system optimizations";
    };

    realTimeKernel = mkOption {
      type = types.bool;
      default = false;
      description = "Use real-time Linux kernel";
    };

    cpuGovernor = mkOption {
      type = types.enum ["performance" "powersave" "ondemand" "conservative" "schedutil"];
      default = "performance";
      description = "CPU frequency governor";
    };

    kernelParams = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional kernel boot parameters";
    };

    sysctl = mkOption {
      type = types.attrsOf (types.oneOf [types.int types.str]);
      default = {};
      description = "Kernel sysctl parameters";
    };

    nvme = {
      optimize = mkOption {
        type = types.bool;
        default = false;
        description = "Optimize NVMe settings";
      };
    };

    cpuIsolation = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable CPU isolation for dedicated workload cores (isolcpus, nohz_full, rcu_nocbs)";
      };
    };

    nvidia = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA optimizations";
      };
    };

    boot = {
      timeout = mkOption {
        type = types.int;
        default = 1;
        description = "Boot loader timeout in seconds";
      };

      configurationLimit = mkOption {
        type = types.int;
        default = 100;
        description = "Maximum number of boot configurations to keep";
      };

      initrdCompress = mkOption {
        type = types.str;
        default = "lz4";
        description = "Initrd compression algorithm";
      };
    };

    journald = {
      storage = mkOption {
        type = types.enum ["auto" "volatile" "persistent" "none"];
        default = "volatile";
        description = "Journal storage mode";
      };

      systemMaxUse = mkOption {
        type = types.str;
        default = "100M";
        description = "Maximum disk space for journal";
      };
    };

    systemd = {
      defaultTimeoutStartSec = mkOption {
        type = types.str;
        default = "10s";
        description = "Default service start timeout";
      };

      defaultTimeoutStopSec = mkOption {
        type = types.str;
        default = "10s";
        description = "Default service stop timeout";
      };

      waitOnline = mkOption {
        type = types.bool;
        default = false;
        description = "Wait for network to be online";
      };
    };

    getty = {
      autovts = mkOption {
        type = types.int;
        default = 2;
        description = "Number of automatic virtual terminals";
      };
    };

    nix = {
      gcAutomatic = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic garbage collection";
      };

      gcDates = mkOption {
        type = types.str;
        default = "weekly";
        description = "When to run automatic garbage collection";
      };

      gcOptions = mkOption {
        type = types.str;
        default = "--delete-older-than 30d";
        description = "Options for garbage collection";
      };

      optimiseAutomatic = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic store optimization";
      };

      optimiseDates = mkOption {
        type = types.listOf types.str;
        default = ["06:00"];
        description = "When to run automatic store optimization";
      };

      extraOptions = mkOption {
        type = types.lines;
        default = "";
        description = "Extra nix configuration";
      };
    };

    printing = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable CUPS printing support";
      };

      drivers = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Printer drivers to install";
      };
    };

    avahi = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Avahi mDNS/DNS-SD daemon";
      };
    };
  };

  config = mkIf (profileCfg.enable && cfg.enable) (mkMerge [
    # Base optimizations
    {
      powerManagement.cpuFreqGovernor = cfg.cpuGovernor;
      boot.kernelParams = cfg.kernelParams;
      boot.kernel.sysctl = cfg.sysctl;
    }

    # K3s-optimized performance (headless-dev, server, and agent variants)
    (mkIf (profileCfg.variant == "headless-dev" || profileCfg.variant == "server" || profileCfg.variant == "agent") {
      boot.kernel.sysctl = {
        # ========== CONTAINER NETWORKING ==========
        # IP forwarding and bridge netfilter settings handled by k3s module

        # ========== CONNECTION TRACKING ==========
        # Critical: k3s workloads can exhaust conntrack table
        # Research shows k3s auto-sets to 131k, we go higher for production
        "net.netfilter.nf_conntrack_max" = 2097152;  # 2M connections
        "net.nf_conntrack_max" = 2097152;
        "net.netfilter.nf_conntrack_buckets" = 524288;  # buckets = max/4
        "net.netfilter.nf_conntrack_tcp_timeout_established" = 86400;  # 24h for long-lived connections
        "net.netfilter.nf_conntrack_tcp_timeout_close_wait" = 60;
        "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 30;

        # ========== MEMORY MANAGEMENT ==========
        # Allow kernel to overcommit memory (critical for containers)
        "vm.overcommit_memory" = 1;
        "vm.panic_on_oom" = 0;  # Don't panic on OOM, let k8s handle it
        "vm.oom_kill_allocating_task" = 1;  # Kill the task that triggered OOM

        # Memory mapping limits for Elasticsearch, databases in containers
        "vm.max_map_count" = 524288;  # Double the default for high-density workloads

        # Swap behavior (minimize swapping for container workloads)
        "vm.swappiness" = 1;  # Almost never swap unless critical

        # Dirty page management for container I/O
        # Note: dirty_ratio, dirty_background_ratio, vfs_cache_pressure are
        # overridden in server/agent variant blocks for more aggressive tuning
        "vm.dirty_expire_centisecs" = 3000;  # 30 seconds
        "vm.dirty_writeback_centisecs" = 500;  # 5 seconds

        # ========== FILE SYSTEM LIMITS ==========
        # File handles for many containers/pods
        "fs.file-max" = 2097152;  # System-wide file handle limit
        "fs.nr_open" = 2097152;  # Per-process file descriptor limit

        # Inotify for kubectl logs, nginx ingress, monitoring
        "fs.inotify.max_user_watches" = 1048576;  # 1M watches
        "fs.inotify.max_user_instances" = 8192;
        "fs.inotify.max_queued_events" = 32768;

        # AIO limits for databases in containers
        "fs.aio-max-nr" = 1048576;

        # ========== NETWORK STACK TUNING ==========
        # Core network buffers
        "net.core.somaxconn" = 65535;  # Max connection queue
        "net.core.netdev_max_backlog" = 65536;  # RX packet queue
        "net.core.rmem_max" = 134217728;  # 128MB max receive buffer
        "net.core.wmem_max" = 134217728;  # 128MB max send buffer
        "net.core.rmem_default" = 16777216;  # 16MB default RX
        "net.core.wmem_default" = 16777216;  # 16MB default TX
        "net.core.optmem_max" = 40960;  # Max ancillary buffer size

        # TCP tuning for low latency and high throughput
        "net.ipv4.tcp_rmem" = "4096 87380 134217728";  # min default max
        "net.ipv4.tcp_wmem" = "4096 87380 134217728";
        "net.ipv4.tcp_mem" = "786432 1048576 26777216";  # pages
        "net.ipv4.udp_rmem_min" = 16384;
        "net.ipv4.udp_wmem_min" = 16384;

        # TCP stack optimizations
        "net.ipv4.tcp_max_syn_backlog" = 65536;
        "net.ipv4.tcp_slow_start_after_idle" = 0;  # Disable for persistent connections
        "net.ipv4.tcp_tw_reuse" = 1;  # Reuse TIME_WAIT sockets
        "net.ipv4.tcp_fin_timeout" = 15;  # Reduce FIN_WAIT_2 timeout
        "net.ipv4.tcp_keepalive_time" = 300;  # 5 minutes
        "net.ipv4.tcp_keepalive_probes" = 5;
        "net.ipv4.tcp_keepalive_intvl" = 15;

        # TCP congestion control (BBR for better throughput)
        "net.core.default_qdisc" = "fq";  # Fair queue for BBR
        "net.ipv4.tcp_congestion_control" = "bbr";

        # TCP window scaling
        "net.ipv4.tcp_window_scaling" = 1;
        "net.ipv4.tcp_timestamps" = 1;
        "net.ipv4.tcp_sack" = 1;

        # Disable IPv4 source routing for security
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;

        # SYN cookies for DDoS protection
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_max_tw_buckets" = 1440000;

        # Local port range for outbound connections
        "net.ipv4.ip_local_port_range" = "10000 65535";

        # Netfilter connection tracking timeouts
        "net.ipv4.tcp_max_orphans" = 262144;
        "net.ipv4.tcp_orphan_retries" = 0;

        # ========== SCHEDULER & PERFORMANCE ==========
        # Process scheduling
        "kernel.sched_migration_cost_ns" = 5000000;  # 5ms
        "kernel.sched_autogroup_enabled" = 0;  # Disable for server workloads

        # Increase PID limit for many containers
        "kernel.pid_max" = 4194304;  # 4M PIDs
        "kernel.threads-max" = 4194304;

        # Core dumps (disable to save disk space)
        "kernel.core_pattern" = "|/bin/false";

        # Kernel message logging
        "kernel.printk" = "3 4 1 3";  # Reduce kernel log verbosity

        # Watchdog (disable if not needed)
        "kernel.nmi_watchdog" = 0;

        # ========== SECURITY (while maintaining performance) ==========
        # Restrict kernel pointer exposure
        "kernel.kptr_restrict" = 1;

        # Restrict dmesg access
        "kernel.dmesg_restrict" = 1;

        # Harden BPF JIT
        "net.core.bpf_jit_harden" = 1;
      };

      boot.kernelParams = [
        # ========== CGROUP & CONTAINER SUPPORT ==========
        "cgroup_enable=cpuset"
        "cgroup_enable=memory"
        "cgroup_memory=1"
        "systemd.unified_cgroup_hierarchy=0"  # Use cgroup v1 for k3s compatibility

        # ========== MEMORY & CPU ==========
        "transparent_hugepage=never"  # THP causes latency spikes in containers

        # ========== NETWORK ==========
        "ipv6.disable=0"  # Keep IPv6 enabled for dual-stack k3s

        # ========== SECURITY ==========
        "lockdown=confidentiality"  # Kernel lockdown for security
      ] ++ (optionals cfg.cpuIsolation.enable [
        # ========== CPU ISOLATION (optional) ==========
        # WARNING: These parameters isolate CPUs from general system workload
        # Only enable if you need dedicated CPUs for specific workloads
        # When disabled, kernel scheduler will distribute work across all cores
        "nohz_full=1-3"  # Tickless mode for CPU 1-3 (adjust based on cores)
        "rcu_nocbs=1-3"  # Offload RCU callbacks from app CPUs
        "isolcpus=nohz,domain,1-3"  # Isolate CPUs for critical workloads
      ]);

      # ========== KERNEL MODULES ==========
      boot.kernelModules = [
        "br_netfilter"  # Bridge netfilter for k8s
        "overlay"  # Overlay FS for containers
        "ip_vs"  # IPVS for kube-proxy
        "ip_vs_rr"  # Round-robin IPVS
        "ip_vs_wrr"  # Weighted round-robin
        "ip_vs_sh"  # Source hashing
        "nf_conntrack"  # Connection tracking
      ];

      # ========== ULIMITS ==========
      # System-wide limits for container workloads
      security.pam.loginLimits = [
        { domain = "*"; type = "soft"; item = "nofile"; value = "1048576"; }
        { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
        { domain = "*"; type = "soft"; item = "nproc"; value = "unlimited"; }
        { domain = "*"; type = "hard"; item = "nproc"; value = "unlimited"; }
        { domain = "*"; type = "soft"; item = "memlock"; value = "unlimited"; }
        { domain = "*"; type = "hard"; item = "memlock"; value = "unlimited"; }
      ];

      # ========== ENSURE HEADLESS OPERATION ==========
      # X server disabled for headless variants
      # Note: hardware.graphics controlled by modules that need it (gpu, hashcat, etc.)
      services.xserver.enable = false;

      # ========== SYSTEMD OPTIMIZATIONS ==========
      systemd.extraConfig = ''
        DefaultLimitNOFILE=1048576
        DefaultLimitNPROC=infinity
        DefaultLimitMEMLOCK=infinity
        DefaultTasksMax=infinity
      '';

      # ========== JOURNALD - Reduce disk I/O ==========
      services.journald.extraConfig = ''
        SystemMaxUse=500M
        SystemMaxFileSize=50M
        MaxRetentionSec=7day
        MaxFileSec=1day
        RateLimitInterval=30s
        RateLimitBurst=10000
        ForwardToSyslog=no
        ForwardToKMsg=no
        ForwardToConsole=no
        ForwardToWall=no
      '';

      # ========== STORAGE I/O OPTIMIZATIONS ==========
      # NVMe-specific optimizations
      services.udev.extraRules = ''
        # NVMe: Use none scheduler for best latency
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/iosched/low_latency}="1"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/read_ahead_kb}="256"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="1024"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/rq_affinity}="2"

        # SSD: Use mq-deadline or kyber for SSDs
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/read_ahead_kb}="256"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/nr_requests}="1024"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/rq_affinity}="2"

        # HDD: Use mq-deadline for rotational disks
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="mq-deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/read_ahead_kb}="4096"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/nr_requests}="128"

        # Set I/O priority for k3s processes (best-effort, priority 0 = highest)
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{bdi/read_ahead_kb}="256"
      '';

      # ========== CPU FREQUENCY SCALING ==========
      # Use performance governor for predictable latency
      powerManagement.cpuFreqGovernor = "performance";

      # Disable CPU idle states for maximum responsiveness (optional, increases power usage)
      # boot.kernelParams already includes nohz_full and rcu_nocbs

      # ========== HUGE PAGES ==========
      # Pre-allocate huge pages for database workloads (optional)
      # boot.kernel.sysctl."vm.nr_hugepages" = 1024;  # 2GB with 2MB pages

      # ========== TMPFS OPTIMIZATIONS ==========
      # Use tmpfs for ephemeral container data to reduce I/O
      # Only set if not already configured
      fileSystems."/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "nosuid" "nodev" "size=8G" "mode=1777" ];
      };

      # ========== DISABLE UNNECESSARY KERNEL FEATURES ==========
      boot.blacklistedKernelModules = [
        "bluetooth"  # Disable Bluetooth
        "btusb"
        "pcspkr"  # Disable PC speaker
        "snd_pcsp"
      ];

      # ========== IRQBALANCE ==========
      # Distribute IRQs across CPUs for better throughput
      services.irqbalance.enable = true;

      # ========== TUNE NETWORK INTERFACES ==========
      # Increase network interface ring buffers
      systemd.services.tune-network-interfaces = {
        description = "Tune network interface ring buffers for k3s";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # Find all network interfaces
          for iface in $(ls /sys/class/net/ | grep -v lo); do
            # Increase RX/TX ring buffers if supported
            /run/current-system/sw/bin/ethtool -G $iface rx 4096 tx 4096 2>/dev/null || true

            # Enable hardware offloading
            /run/current-system/sw/bin/ethtool -K $iface gso on 2>/dev/null || true
            /run/current-system/sw/bin/ethtool -K $iface tso on 2>/dev/null || true
            /run/current-system/sw/bin/ethtool -K $iface gro on 2>/dev/null || true

            # Increase number of RSS queues
            /run/current-system/sw/bin/ethtool -L $iface combined 4 2>/dev/null || true
          done
        '';
      };

      # ========== MONITORING TOOLS ==========
      # Include performance monitoring tools
      environment.systemPackages = with pkgs; [
        ethtool
        iftop
        iotop
        sysstat
        numactl
        perf-tools
        bpftrace
      ];
    })

    # ========== SERVER & AGENT VARIANTS - MAXIMUM K3S OPTIMIZATION ==========
    (mkIf (profileCfg.variant == "server" || profileCfg.variant == "agent") {
      # Even more aggressive optimizations for dedicated k3s nodes

      # Force-disable audio and bluetooth on server/agent — no desktop peripherals
      services.pipewire.enable = lib.mkForce false;
      hardware.bluetooth.enable = lib.mkForce false;
      services.blueman.enable = lib.mkForce false;

      # Minimal journald
      services.journald.extraConfig = ''
        SystemMaxUse=200M
        SystemMaxFileSize=20M
        MaxRetentionSec=3day
      '';

      # Disable documentation to save space
      documentation.enable = false;
      documentation.man.enable = false;
      documentation.info.enable = false;
      documentation.doc.enable = false;

      # Aggressive kernel page cache tuning
      boot.kernel.sysctl = {
        "vm.vfs_cache_pressure" = 10;  # Aggressively retain cache
        "vm.dirty_ratio" = 60;  # Allow more dirty pages before blocking
        "vm.dirty_background_ratio" = 5;  # Start writeback earlier
      };
    })

    # ========== AGENT VARIANT - PURE WORKLOAD NODE ==========
    (mkIf (profileCfg.variant == "agent") {
      # Agent nodes run only workloads, no control plane
      # Maximum resource dedication to container workloads

      # Even more aggressive connection tracking for pure worker nodes
      # mkForce needed: these override the base k3s values from the headless-dev/server/agent block
      boot.kernel.sysctl = {
        "net.netfilter.nf_conntrack_max" = mkForce 4194304;  # 4M connections
        "net.nf_conntrack_max" = mkForce 4194304;
        "net.netfilter.nf_conntrack_buckets" = mkForce 1048576;  # 1M buckets

        # Maximize memory for workloads
        "vm.min_free_kbytes" = 65536;  # Keep 64MB free for critical allocations

        # Optimize for maximum throughput
        "net.core.netdev_budget" = 600;  # Process more packets per NAPI poll
        "net.core.netdev_budget_usecs" = 8000;  # Increase NAPI poll time
      };

      # Disable audit to reduce overhead
      boot.kernelParams = [
        "audit=0"
      ];

      # Aggressive I/O for container workloads
      services.udev.extraRules = ''
        # Maximize NVMe queue depth for container I/O
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="2048"

        # Increase max_sectors_kb for larger I/O operations
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/max_sectors_kb}="2048"
      '';

      # No shell aliases needed (agent-only, minimal interaction)
      environment.shellAliases = {};
    })

    # Common system configuration (all variants)
    {
      boot.loader.timeout = cfg.boot.timeout;
      boot.loader.systemd-boot.configurationLimit = cfg.boot.configurationLimit;
      boot.initrd.compressor =
        if cfg.boot.initrdCompress == "lz4" then "${pkgs.lz4.out}/bin/lz4 -l"
        else if cfg.boot.initrdCompress == "zstd" then "${pkgs.zstd.out}/bin/zstd -19 -T0"
        else if cfg.boot.initrdCompress == "xz" then "${pkgs.xz.out}/bin/xz"
        else if cfg.boot.initrdCompress == "gzip" then "${pkgs.gzip.out}/bin/gzip"
        else null;

      services.journald.storage = cfg.journald.storage;
      services.journald.extraConfig = ''
        SystemMaxUse=${cfg.journald.systemMaxUse}
      '';

      systemd.extraConfig = ''
        DefaultTimeoutStartSec=${cfg.systemd.defaultTimeoutStartSec}
        DefaultTimeoutStopSec=${cfg.systemd.defaultTimeoutStopSec}
      '';
      systemd.network.wait-online.enable = cfg.systemd.waitOnline;

      # Nix GC and optimization settings are handled by nix-performance.nix module
      # Only set extraOptions here if provided
      nix.extraOptions = mkIf (cfg.nix.extraOptions != "") cfg.nix.extraOptions;

      services.printing = mkIf cfg.printing.enable {
        enable = true;
        drivers = cfg.printing.drivers;
      };

      services.avahi = mkIf cfg.avahi.enable {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };

      # Disable some services for performance
      hardware.bluetooth.enable = lib.mkDefault false;
    }

    # Real-time kernel
    (mkIf cfg.realTimeKernel {
      boot.kernelPackages = pkgs.linuxPackages-rt;
    })

    # NVMe optimizations
    (mkIf cfg.nvme.optimize {
      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="nvme0n1", ATTR{queue/scheduler}="none"
      '';

      environment.systemPackages = [pkgs.nvme-cli];
    })

    # NVIDIA optimizations
    (mkIf cfg.nvidia.enable {
      environment.variables = {
        "__GL_MaxFramesAllowed" = "1";
        "__GL_GSYNC_ALLOWED" = "1";
        "__GL_VRR_ALLOWED" = "1";
      };
    })
  ]);
}
