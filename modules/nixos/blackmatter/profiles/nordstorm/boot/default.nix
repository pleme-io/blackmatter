# modules/nixos/blackmatter/profiles/nordstorm/boot/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      # File and process limits
      "fs.file-max" = 2097152;
      "kernel.pid_max" = 4194304;

      # Memory management - Optimize for developer workstation
      "vm.swappiness" = 10; # Avoid early swapping, prefer RAM
      "vm.vfs_cache_pressure" = 50; # Keep inode/dentry caches longer
      "vm.dirty_ratio" = 10; # Start background write at 10% dirty pages
      "vm.dirty_background_ratio" = 5; # Background write threshold

      # Network performance
      "net.core.rmem_max" = 134217728; # 128 MB receive buffer
      "net.core.wmem_max" = 134217728; # 128 MB send buffer
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      "net.ipv4.tcp_fastopen" = 3; # Enable TCP Fast Open

      # File system optimizations
      "fs.inotify.max_user_watches" = 524288; # For IDEs and file watchers
      "fs.inotify.max_user_instances" = 512;
    };

    boot.kernelParams = [
      "nvidia-drm.modeset=1"
      "fbdev=1"
      "selinux=0"
      "apparmor=0"
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
