# modules/nixos/blackmatter/profiles/blizzard/server-monitoring/default.nix
# Server monitoring: smartd, journald, logrotate, monitoring tools
# Extracted from pleme-io/nix nodes/zek/survivability/{self-healing,monitoring-infrastructure}.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.serverMonitoring;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.serverMonitoring = {
    enable = mkEnableOption "server monitoring and health services";

    # ── S.M.A.R.T. disk monitoring ────────────────────────────────
    smartd = {
      enable = mkEnableOption "S.M.A.R.T. disk health monitoring";

      autodetect = mkOption {
        type = types.bool;
        default = true;
        description = "Auto-detect disks for monitoring.";
      };

      wallNotify = mkOption {
        type = types.bool;
        default = false;
        description = "Send wall notifications on disk issues.";
      };

      mailNotify = mkOption {
        type = types.bool;
        default = false;
        description = "Send mail notifications on disk issues.";
      };
    };

    # ── journald ──────────────────────────────────────────────────
    journald = {
      enable = mkEnableOption "enhanced journald configuration";

      storage = mkOption {
        type = types.str;
        default = "persistent";
        description = "Journal storage mode (volatile, persistent, auto, none).";
      };

      systemMaxUse = mkOption {
        type = types.str;
        default = "1G";
        description = "Maximum disk space for journal files.";
      };

      compress = mkOption {
        type = types.bool;
        default = true;
        description = "Compress older journal entries.";
      };

      syncInterval = mkOption {
        type = types.str;
        default = "5m";
        description = "Sync interval for crash recovery.";
      };

      forwardToWall = mkOption {
        type = types.bool;
        default = true;
        description = "Forward important messages to wall.";
      };
    };

    # ── logrotate ─────────────────────────────────────────────────
    logrotate = {
      enable = mkEnableOption "advanced log rotation";

      globalRotate = mkOption {
        type = types.int;
        default = 14;
        description = "Default number of rotated log files to keep.";
      };

      globalMaxSize = mkOption {
        type = types.str;
        default = "50M";
        description = "Default max size before rotation.";
      };

      extraLogs = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            rotate = mkOption {
              type = types.int;
              default = 14;
              description = "Number of rotated files to keep.";
            };
            size = mkOption {
              type = types.str;
              default = "50M";
              description = "Max file size before rotation.";
            };
            daily = mkOption {
              type = types.bool;
              default = true;
              description = "Rotate daily.";
            };
            compress = mkOption {
              type = types.bool;
              default = true;
              description = "Compress rotated logs.";
            };
          };
        });
        default = {};
        description = "Extra log file paths and their rotation settings.";
      };
    };

    # ── Monitoring tools ──────────────────────────────────────────
    tools = mkEnableOption "monitoring tools (iotop, vnstat, sysstat, atop, lnav)";
  };

  config = mkIf (profileCfg.enable && cfg.enable) (mkMerge [
    # ── smartd ───────────────────────────────────────────────────
    (mkIf cfg.smartd.enable {
      services.smartd = {
        enable = true;
        autodetect = cfg.smartd.autodetect;
        notifications = {
          wall.enable = cfg.smartd.wallNotify;
          mail.enable = cfg.smartd.mailNotify;
        };
      };
    })

    # ── journald ─────────────────────────────────────────────────
    (mkIf cfg.journald.enable {
      services.journald.extraConfig = ''
        Storage=${cfg.journald.storage}
        SystemMaxUse=${cfg.journald.systemMaxUse}
        Compress=${
          if cfg.journald.compress
          then "yes"
          else "no"
        }
        ForwardToWall=${
          if cfg.journald.forwardToWall
          then "yes"
          else "no"
        }
        SyncIntervalSec=${cfg.journald.syncInterval}
      '';
    })

    # ── logrotate ────────────────────────────────────────────────
    (mkIf cfg.logrotate.enable {
      services.logrotate = {
        enable = true;
        settings =
          {
            global = {
              daily = mkDefault true;
              rotate = mkDefault cfg.logrotate.globalRotate;
              create = mkDefault true;
              dateext = mkDefault true;
              compress = mkDefault true;
              delaycompress = mkDefault true;
              missingok = mkDefault true;
              notifempty = mkDefault true;
              sharedscripts = mkDefault true;
            };
          }
          // mapAttrs (_path: logCfg: {
            rotate = logCfg.rotate;
            daily = logCfg.daily;
            size = logCfg.size;
            compress = logCfg.compress;
          })
          cfg.logrotate.extraLogs;
      };
    })

    # ── Monitoring tools ─────────────────────────────────────────
    (mkIf cfg.tools {
      environment.systemPackages = with pkgs; [
        iotop
        vnstat
        sysstat
        atop
        lnav
      ];
    })
  ]);
}
