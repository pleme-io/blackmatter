# modules/nixos/blackmatter/components/system-limits/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.systemLimits;
in {
  options.blackmatter.components.systemLimits = {
    enable = mkEnableOption "system PAM login limits (high file/process/memory limits)";

    # Canonical fleet ceiling = 2^24 (16,777,216) open files per process — max
    # headroom by default everywhere (operator decision 2026-06-30). Peer faces:
    # Darwin blackmatter.profiles.macos.limits (launchctl) +
    # pleme.darwin.profiles.developerResources (sysctl); HM
    # blackmatter.components.fdLimits (shell ulimit).
    nofile = mkOption {
      type = types.int;
      default = 16777216;
      description = ''
        Per-process open-file ceiling applied via PAM (login sessions),
        systemd DefaultLimitNOFILE (services + user units), and the
        fs.nr_open kernel cap. PAM/systemd nofile above 1048576 is silently
        clamped unless fs.nr_open is raised to match — this module does both.
      '';
    };
  };

  config = mkIf cfg.enable {
    # fs.nr_open is the kernel's per-process hard ceiling for RLIMIT_NOFILE
    # (default 1048576). PAM/systemd cannot grant more than this, so raise it
    # to the canonical ceiling first. fs.file-max is the system-wide cap.
    boot.kernel.sysctl = {
      "fs.nr_open" = cfg.nofile;
      "fs.file-max" = cfg.nofile * 2;
    };

    # PAM (security.pam.loginLimits) only governs login sessions (ssh, tty).
    # systemd services + user units take their limit from DefaultLimitNOFILE,
    # so set both to cover every process-launch path. The system-level
    # `systemd.extraConfig` was removed in newer nixpkgs → the freeform
    # `systemd.settings.Manager` renders /etc/systemd/system.conf's [Manager];
    # `systemd.user.extraConfig` is still current for the user manager.
    #
    # `mkForce`: systemLimits is the fleet FD authority (the max-headroom
    # decision). Other profiles (e.g. blizzard/optimizations) also set
    # DefaultLimitNOFILE at normal priority — without mkForce the two collide
    # and FAIL eval on every blizzard node (rio: this broke the rebuild that
    # would deploy the k3s crash-loop fix, 2026-07-01). systemLimits wins.
    # TODO(consolidate): blizzard/optimizations should defer its DefaultLimitNOFILE
    # to systemLimits so FD config lives in exactly one place.
    systemd.settings.Manager.DefaultLimitNOFILE = mkForce "${toString cfg.nofile}:${toString cfg.nofile}";
    systemd.user.extraConfig = "DefaultLimitNOFILE=${toString cfg.nofile}:${toString cfg.nofile}";

    security.pam.loginLimits = [
      {
        value = toString cfg.nofile;
        item = "nofile";
        type = "soft";
        domain = "*";
      }
      {
        value = toString cfg.nofile;
        item = "nofile";
        type = "hard";
        domain = "*";
      }
      {
        value = "65536";
        item = "nproc";
        type = "soft";
        domain = "*";
      }
      {
        value = "65536";
        item = "nproc";
        type = "hard";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "stack";
        type = "soft";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "stack";
        type = "hard";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "memlock";
        type = "soft";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "memlock";
        type = "hard";
        domain = "*";
      }
      {
        value = "unlimited";
        type = "soft";
        domain = "*";
        item = "rss";
      }
      {
        value = "unlimited";
        type = "hard";
        domain = "*";
        item = "rss";
      }
    ];
  };
}
