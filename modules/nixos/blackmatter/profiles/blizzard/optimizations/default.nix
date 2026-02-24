# modules/nixos/blackmatter/profiles/blizzard/optimizations/default.nix
#
# K3s-specific and variant-dependent system optimizations.
# Generic base tuning (boot loader, journald, systemd timeouts, Nix GC, printing/avahi)
# has been extracted to blackmatter.components.baseSystemTuning.
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

    getty = {
      autovts = mkOption {
        type = types.int;
        default = 2;
        description = "Number of automatic virtual terminals";
      };
    };
  };

  config = mkIf (profileCfg.enable && cfg.enable) (mkMerge [
    # Base optimizations
    {
      powerManagement.cpuFreqGovernor = cfg.cpuGovernor;
      boot.kernelParams = cfg.kernelParams;
      boot.kernel.sysctl = cfg.sysctl;

      # Enable generic base tuning component
      blackmatter.components.baseSystemTuning.enable = true;
    }

    # K3s-optimized performance (headless-dev, server, and agent variants)
    (mkIf (profileCfg.variant == "headless-dev" || profileCfg.variant == "server" || profileCfg.variant == "agent") {
      boot.kernel.sysctl = {
        # ========== CONNECTION TRACKING ==========
        "net.netfilter.nf_conntrack_max" = 2097152;
        "net.nf_conntrack_max" = 2097152;
        "net.netfilter.nf_conntrack_buckets" = 524288;
        "net.netfilter.nf_conntrack_tcp_timeout_established" = 86400;
        "net.netfilter.nf_conntrack_tcp_timeout_close_wait" = 60;
        "net.netfilter.nf_conntrack_tcp_timeout_time_wait" = 30;

        # ========== MEMORY MANAGEMENT ==========
        "vm.overcommit_memory" = 1;
        "vm.panic_on_oom" = 0;
        "vm.oom_kill_allocating_task" = 1;
        "vm.max_map_count" = 524288;
        "vm.swappiness" = 1;
        "vm.dirty_expire_centisecs" = 3000;
        "vm.dirty_writeback_centisecs" = 500;

        # ========== FILE SYSTEM LIMITS ==========
        "fs.file-max" = 2097152;
        "fs.nr_open" = 2097152;
        "fs.inotify.max_user_watches" = 1048576;
        "fs.inotify.max_user_instances" = 8192;
        "fs.inotify.max_queued_events" = 32768;
        "fs.aio-max-nr" = 1048576;

        # ========== NETWORK STACK TUNING ==========
        "net.core.somaxconn" = 65535;
        "net.core.netdev_max_backlog" = 65536;
        "net.core.rmem_max" = 134217728;
        "net.core.wmem_max" = 134217728;
        "net.core.rmem_default" = 16777216;
        "net.core.wmem_default" = 16777216;
        "net.core.optmem_max" = 40960;
        "net.ipv4.tcp_rmem" = "4096 87380 134217728";
        "net.ipv4.tcp_wmem" = "4096 87380 134217728";
        "net.ipv4.tcp_mem" = "786432 1048576 26777216";
        "net.ipv4.udp_rmem_min" = 16384;
        "net.ipv4.udp_wmem_min" = 16384;
        "net.ipv4.tcp_max_syn_backlog" = 65536;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        "net.ipv4.tcp_tw_reuse" = 1;
        "net.ipv4.tcp_fin_timeout" = 15;
        "net.ipv4.tcp_keepalive_time" = 300;
        "net.ipv4.tcp_keepalive_probes" = 5;
        "net.ipv4.tcp_keepalive_intvl" = 15;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_window_scaling" = 1;
        "net.ipv4.tcp_timestamps" = 1;
        "net.ipv4.tcp_sack" = 1;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_max_tw_buckets" = 1440000;
        "net.ipv4.ip_local_port_range" = "10000 65535";
        "net.ipv4.tcp_max_orphans" = 262144;
        "net.ipv4.tcp_orphan_retries" = 0;

        # ========== SCHEDULER & PERFORMANCE ==========
        "kernel.sched_migration_cost_ns" = 5000000;
        "kernel.sched_autogroup_enabled" = 0;
        "kernel.pid_max" = 4194304;
        "kernel.threads-max" = 4194304;
        "kernel.core_pattern" = "|/bin/false";
        "kernel.printk" = "3 4 1 3";
        "kernel.nmi_watchdog" = 0;

        # ========== SECURITY ==========
        "kernel.kptr_restrict" = 1;
        "kernel.dmesg_restrict" = 1;
        "net.core.bpf_jit_harden" = 1;
      };

      boot.kernelParams = [
        "cgroup_enable=cpuset"
        "cgroup_enable=memory"
        "cgroup_memory=1"
        "systemd.unified_cgroup_hierarchy=0"
        "transparent_hugepage=never"
        "ipv6.disable=0"
        "lockdown=confidentiality"
      ] ++ (optionals cfg.cpuIsolation.enable [
        "nohz_full=1-3"
        "rcu_nocbs=1-3"
        "isolcpus=nohz,domain,1-3"
      ]);

      boot.kernelModules = [
        "br_netfilter"
        "overlay"
        "ip_vs"
        "ip_vs_rr"
        "ip_vs_wrr"
        "ip_vs_sh"
        "nf_conntrack"
      ];

      security.pam.loginLimits = [
        { domain = "*"; type = "soft"; item = "nofile"; value = "1048576"; }
        { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; }
        { domain = "*"; type = "soft"; item = "nproc"; value = "unlimited"; }
        { domain = "*"; type = "hard"; item = "nproc"; value = "unlimited"; }
        { domain = "*"; type = "soft"; item = "memlock"; value = "unlimited"; }
        { domain = "*"; type = "hard"; item = "memlock"; value = "unlimited"; }
      ];

      services.xserver.enable = false;

      systemd.extraConfig = ''
        DefaultLimitNOFILE=1048576
        DefaultLimitNPROC=infinity
        DefaultLimitMEMLOCK=infinity
        DefaultTasksMax=infinity
      '';

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

      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/iosched/low_latency}="1"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/read_ahead_kb}="256"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="1024"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/rq_affinity}="2"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/read_ahead_kb}="256"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/nr_requests}="1024"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/rq_affinity}="2"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="mq-deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/read_ahead_kb}="4096"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/nr_requests}="128"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{bdi/read_ahead_kb}="256"
      '';

      powerManagement.cpuFreqGovernor = "performance";

      fileSystems."/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "nosuid" "nodev" "size=8G" "mode=1777" ];
      };

      boot.blacklistedKernelModules = [
        "bluetooth"
        "btusb"
        "pcspkr"
        "snd_pcsp"
      ];

      services.irqbalance.enable = true;

      systemd.services.tune-network-interfaces = {
        description = "Tune network interface ring buffers for k3s";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          for iface in $(ls /sys/class/net/ | grep -v lo); do
            /run/current-system/sw/bin/ethtool -G $iface rx 4096 tx 4096 2>/dev/null || true
            /run/current-system/sw/bin/ethtool -K $iface gso on 2>/dev/null || true
            /run/current-system/sw/bin/ethtool -K $iface tso on 2>/dev/null || true
            /run/current-system/sw/bin/ethtool -K $iface gro on 2>/dev/null || true
            /run/current-system/sw/bin/ethtool -L $iface combined 4 2>/dev/null || true
          done
        '';
      };

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

    # Server & Agent variants - maximum K3s optimization
    (mkIf (profileCfg.variant == "server" || profileCfg.variant == "agent") {
      services.pipewire.enable = lib.mkForce false;
      hardware.bluetooth.enable = lib.mkForce false;
      services.blueman.enable = lib.mkForce false;

      services.journald.extraConfig = ''
        SystemMaxUse=200M
        SystemMaxFileSize=20M
        MaxRetentionSec=3day
      '';

      documentation.enable = false;
      documentation.man.enable = false;
      documentation.info.enable = false;
      documentation.doc.enable = false;

      boot.kernel.sysctl = {
        "vm.vfs_cache_pressure" = 10;
        "vm.dirty_ratio" = 60;
        "vm.dirty_background_ratio" = 5;
      };
    })

    # Agent variant - pure workload node
    (mkIf (profileCfg.variant == "agent") {
      boot.kernel.sysctl = {
        "net.netfilter.nf_conntrack_max" = mkForce 4194304;
        "net.nf_conntrack_max" = mkForce 4194304;
        "net.netfilter.nf_conntrack_buckets" = mkForce 1048576;
        "vm.min_free_kbytes" = 65536;
        "net.core.netdev_budget" = 600;
        "net.core.netdev_budget_usecs" = 8000;
      };

      boot.kernelParams = [
        "audit=0"
      ];

      services.udev.extraRules = ''
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="2048"
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/max_sectors_kb}="2048"
      '';

      environment.shellAliases = {};
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
