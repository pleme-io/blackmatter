{ config, lib, pkgs, ... }:

let
  cfg = config.blackmatter.components.nix-maintenance;
in
{
  options.blackmatter.components.nix-maintenance = {
    enable = lib.mkEnableOption "Nightly git pull + NixOS rebuild maintenance";

    flakeDir = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the nexus repo (flake root)";
      example = "/home/luis/code/github/pleme-io/nexus";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User who owns the repo (git operations run as this user)";
      example = "luis";
    };

    branch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Git branch to pull";
    };

    schedule = lib.mkOption {
      type = lib.types.str;
      default = "*-*-* 03:00:00";
      description = "systemd calendar spec for when to run maintenance";
    };

    randomDelay = lib.mkOption {
      type = lib.types.str;
      default = "1h";
      description = "Random delay (splay) to avoid simultaneous rebuilds across nodes";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nix-maintenance = {
      description = "Nightly git pull + NixOS rebuild";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      environment = {
        NIX_CONFIG = "experimental-features = nix-command flakes";
      };

      path = with pkgs; [ git nixos-rebuild nix hostname sudo ];

      serviceConfig = {
        Type = "oneshot";
        SyslogIdentifier = "nix-maintenance";
      };

      script = ''
        set -euo pipefail

        FLAKE_DIR="${cfg.flakeDir}"
        BRANCH="${cfg.branch}"
        USER="${cfg.user}"
        HOST=$(hostname)

        echo "=== nix-maintenance: starting at $(date) ==="

        # Git pull as the repo-owning user
        echo "Fetching origin/$BRANCH in $FLAKE_DIR..."
        sudo -u "$USER" git -C "$FLAKE_DIR" fetch origin "$BRANCH"
        sudo -u "$USER" git -C "$FLAKE_DIR" reset --hard "origin/$BRANCH"
        echo "Git updated to $(sudo -u "$USER" git -C "$FLAKE_DIR" rev-parse --short HEAD)"

        # Rebuild NixOS from the flake
        echo "Rebuilding NixOS for $HOST..."
        nixos-rebuild switch --flake "$FLAKE_DIR#$HOST"

        echo "=== nix-maintenance: completed at $(date) ==="
      '';
    };

    systemd.timers.nix-maintenance = {
      description = "Timer for nightly NixOS maintenance";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = cfg.schedule;
        RandomizedDelaySec = cfg.randomDelay;
        Persistent = true;
      };
    };
  };
}
