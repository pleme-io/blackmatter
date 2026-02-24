# modules/nixos/blackmatter/profiles/blizzard/data-persistence/default.nix
# Data persistence: BTRFS snapshots, fstrim, backup tools
# Extracted from pleme-io/nix nodes/zek/survivability/data-persistence.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.dataPersistence;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.dataPersistence = {
    enable = mkEnableOption "data persistence and backup features";

    # ── BTRFS snapshots ───────────────────────────────────────────
    btrfsSnapshots = {
      enable = mkEnableOption "automated BTRFS snapshots via btrbk";

      schedule = mkOption {
        type = types.str;
        default = "hourly";
        description = "Snapshot schedule (systemd calendar expression).";
      };

      preserveMin = mkOption {
        type = types.str;
        default = "6h";
        description = "Minimum snapshot age before pruning.";
      };

      preserve = mkOption {
        type = types.str;
        default = "48h 7d 4w";
        description = "Snapshot retention policy.";
      };

      snapshotDir = mkOption {
        type = types.str;
        default = "/.snapshots";
        description = "Directory for snapshot storage.";
      };

      subvolumes = mkOption {
        type = types.listOf types.str;
        default = ["home" "var/log" "var/lib"];
        description = "BTRFS subvolumes to snapshot.";
      };
    };

    # ── fstrim ────────────────────────────────────────────────────
    fstrim = {
      enable = mkEnableOption "periodic SSD TRIM";

      interval = mkOption {
        type = types.str;
        default = "weekly";
        description = "TRIM schedule (systemd calendar expression).";
      };
    };

    # ── Backup tools ──────────────────────────────────────────────
    backupTools = mkEnableOption "backup tool suite (borgbackup, restic, rsync, rclone)";
  };

  config = mkIf (profileCfg.enable && cfg.enable) (mkMerge [
    # ── BTRFS snapshots ──────────────────────────────────────────
    (mkIf cfg.btrfsSnapshots.enable {
      boot.supportedFilesystems = ["btrfs"];

      environment.systemPackages = [pkgs.btrfs-progs];

      services.btrbk.instances.main = {
        onCalendar = cfg.btrfsSnapshots.schedule;
        settings = {
          timestamp_format = "long-iso";
          preserve_day_of_week = "monday";
          preserve_hour_of_day = "6";

          volume."/" = {
            snapshot_preserve_min = cfg.btrfsSnapshots.preserveMin;
            snapshot_preserve = cfg.btrfsSnapshots.preserve;
            snapshot_dir = cfg.btrfsSnapshots.snapshotDir;
            subvolume = listToAttrs (map (sv: nameValuePair sv {}) cfg.btrfsSnapshots.subvolumes);
          };
        };
      };
    })

    # ── fstrim ───────────────────────────────────────────────────
    (mkIf cfg.fstrim.enable {
      services.fstrim = {
        enable = true;
        interval = cfg.fstrim.interval;
      };
    })

    # ── Backup tools ─────────────────────────────────────────────
    (mkIf cfg.backupTools {
      environment.systemPackages = with pkgs; [
        borgbackup
        restic
        rsync
        rclone
      ];
    })
  ]);
}
