# modules/nixos/blackmatter/profiles/blizzard/laptop-server/default.nix
# Laptop-as-server optimizations: lid, sleep, power, thermal, tethering
# Extracted from pleme-io/nix nodes/zek/laptop-server.nix + network-resilience.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.laptopServer;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.laptopServer = {
    enable = mkEnableOption "laptop-as-server optimizations";

    ignoreLid = mkOption {
      type = types.bool;
      default = true;
      description = "Ignore laptop lid close events (keep running when closed).";
    };

    disableSleep = mkOption {
      type = types.bool;
      default = true;
      description = "Disable sleep, suspend, hibernate, and hybrid-sleep targets.";
    };

    power = {
      cpuGovernor = mkOption {
        type = types.str;
        default = "performance";
        description = "CPU frequency governor.";
      };

      powertopAutoTune = mkOption {
        type = types.bool;
        default = false;
        description = "Enable powertop auto-tune (may disable WiFi).";
      };
    };

    tlp = {
      enable = mkEnableOption "TLP power management for 24/7 operation";

      wifiPowerSave = mkOption {
        type = types.bool;
        default = false;
        description = "Enable WiFi power saving.";
      };

      usbAutoSuspend = mkOption {
        type = types.bool;
        default = false;
        description = "Enable USB auto-suspend.";
      };

      diskSpindown = mkOption {
        type = types.bool;
        default = false;
        description = "Allow disk spindown on idle.";
      };

      cpuGovernorAC = mkOption {
        type = types.str;
        default = "performance";
        description = "CPU governor on AC power.";
      };

      cpuGovernorBAT = mkOption {
        type = types.str;
        default = "performance";
        description = "CPU governor on battery.";
      };
    };

    thermal = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable thermald for thermal management.";
      };
    };

    usbTethering = mkEnableOption "USB tethering fallback (udev rules for rndis_host/cdc_ether)";
    bluetoothTethering = mkEnableOption "Bluetooth for tethering fallback";

    disablePrinting = mkOption {
      type = types.bool;
      default = true;
      description = "Disable CUPS printing service.";
    };
  };

  config = mkIf (profileCfg.enable && cfg.enable) (mkMerge [
    # ── Lid switch ───────────────────────────────────────────────
    (mkIf cfg.ignoreLid {
      services.logind = {
        lidSwitch = "ignore";
        lidSwitchExternalPower = "ignore";
        lidSwitchDocked = "ignore";
      };
    })

    # ── Sleep targets ────────────────────────────────────────────
    (mkIf cfg.disableSleep {
      systemd.targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
    })

    # ── Power management ─────────────────────────────────────────
    {
      powerManagement = {
        enable = true;
        powertop.enable = cfg.power.powertopAutoTune;
        cpuFreqGovernor = cfg.power.cpuGovernor;
      };
    }

    # ── TLP ──────────────────────────────────────────────────────
    (mkIf cfg.tlp.enable {
      services.tlp = {
        enable = true;
        settings = {
          WIFI_PWR_ON_AC =
            if cfg.tlp.wifiPowerSave
            then "on"
            else "off";
          WIFI_PWR_ON_BAT =
            if cfg.tlp.wifiPowerSave
            then "on"
            else "off";
          USB_AUTOSUSPEND =
            if cfg.tlp.usbAutoSuspend
            then 1
            else 0;
          CPU_SCALING_GOVERNOR_ON_AC = cfg.tlp.cpuGovernorAC;
          CPU_SCALING_GOVERNOR_ON_BAT = cfg.tlp.cpuGovernorBAT;
          DISK_SPINDOWN_TIMEOUT_ON_AC =
            if cfg.tlp.diskSpindown
            then "12 12"
            else "0 0";
          DISK_SPINDOWN_TIMEOUT_ON_BAT =
            if cfg.tlp.diskSpindown
            then "12 12"
            else "0 0";
        };
      };
    })

    # ── Thermal ──────────────────────────────────────────────────
    (mkIf cfg.thermal.enable {
      services.thermald.enable = true;
    })

    # ── USB tethering ────────────────────────────────────────────
    (mkIf cfg.usbTethering {
      services.udev.extraRules = ''
        # Auto-configure USB tethering when device connected
        SUBSYSTEM=="net", ACTION=="add", DRIVERS=="rndis_host", RUN+="${pkgs.systemd}/bin/systemctl start usb-tethering@%k.service"
        SUBSYSTEM=="net", ACTION=="add", DRIVERS=="cdc_ether", RUN+="${pkgs.systemd}/bin/systemctl start usb-tethering@%k.service"
      '';
    })

    # ── Bluetooth tethering ──────────────────────────────────────
    (mkIf cfg.bluetoothTethering {
      hardware.bluetooth.enable = true;
      services.blueman.enable = false;
    })

    # ── Printing ─────────────────────────────────────────────────
    (mkIf cfg.disablePrinting {
      services.printing.enable = mkForce false;
    })
  ]);
}
