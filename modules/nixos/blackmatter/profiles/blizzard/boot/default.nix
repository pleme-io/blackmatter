# modules/nixos/blackmatter/profiles/blizzard/boot/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard;
in {
  config = mkIf cfg.enable {
    boot.kernel.sysctl = lib.mkDefault {
      "fs.file-max" = 2097152;
      "kernel.pid_max" = 4194304;
    };
    boot.kernelParams = lib.mkDefault [
      "nvidia-drm.modeset=1"
      "fbdev=1"
      "selinux=0"
      "apparmor=0"
    ];
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
  };
}
