# modules/nixos/blackmatter/components/base-system-tuning/default.nix
#
# Generic base system tuning extracted from blizzard optimizations.
# Boot loader, journald, systemd timeouts, Nix GC, printing/avahi, bluetooth defaults.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.baseSystemTuning;
in {
  options.blackmatter.components.baseSystemTuning = {
    enable = mkEnableOption "base system tuning (boot, journald, systemd, Nix GC)";

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

    realTimeKernel = mkOption {
      type = types.bool;
      default = false;
      description = "Use real-time Linux kernel";
    };
  };

  config = mkIf cfg.enable (mkMerge [
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

      hardware.bluetooth.enable = lib.mkDefault false;
    }

    (mkIf cfg.realTimeKernel {
      boot.kernelPackages = pkgs.linuxPackages-rt;
    })
  ]);
}
