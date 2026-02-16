# modules/nixos/blackmatter/profiles/blizzard/hardware/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.hardware;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.hardware = {
    filesystems = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          device = mkOption {
            type = types.str;
            description = "Device path (e.g., /dev/disk/by-uuid/...)";
          };
          fsType = mkOption {
            type = types.str;
            description = "Filesystem type";
          };
          options = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Mount options";
          };
        };
      });
      default = {};
      description = "Filesystem mounts configuration";
      example = literalExpression ''
        {
          "/" = {
            device = "/dev/disk/by-uuid/...";
            fsType = "ext4";
          };
          "/boot" = {
            device = "/dev/disk/by-uuid/...";
            fsType = "vfat";
            options = ["fmask=0077" "dmask=0077"];
          };
        }
      '';
    };

    swapDevices = mkOption {
      type = types.listOf (types.submodule {
        options = {
          device = mkOption {
            type = types.str;
            description = "Swap device path";
          };
        };
      });
      default = [];
      description = "Swap devices configuration";
    };

    kernel = {
      modules = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional kernel modules to load";
      };

      initrdModules = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Kernel modules available in initrd";
      };

      blacklist = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Kernel modules to blacklist";
      };
    };

    platform = mkOption {
      type = types.str;
      default = "x86_64-linux";
      description = "System platform";
    };

    cpu = {
      type = mkOption {
        type = types.enum ["intel" "amd" "other"];
        default = "other";
        description = "CPU type for microcode updates";
      };

      updateMicrocode = mkOption {
        type = types.bool;
        default = true;
        description = "Enable CPU microcode updates";
      };
    };
  };

  config = mkIf profileCfg.enable {
    fileSystems = mapAttrs (name: fs:
      {
        inherit (fs) device fsType;
      } // optionalAttrs (fs.options != []) {
        options = fs.options;
      }
    ) cfg.filesystems;

    swapDevices = cfg.swapDevices;

    boot.kernelModules = cfg.kernel.modules;
    boot.initrd.availableKernelModules = cfg.kernel.initrdModules;
    boot.initrd.kernelModules = [];  # Explicitly set to empty - modules loaded conditionally from availableKernelModules
    boot.blacklistedKernelModules = cfg.kernel.blacklist;

    nixpkgs.hostPlatform = lib.mkDefault cfg.platform;

    hardware.cpu.intel.updateMicrocode =
      lib.mkIf (cfg.cpu.type == "intel" && cfg.cpu.updateMicrocode)
        (lib.mkDefault config.hardware.enableRedistributableFirmware);

    hardware.cpu.amd.updateMicrocode =
      lib.mkIf (cfg.cpu.type == "amd" && cfg.cpu.updateMicrocode)
        (lib.mkDefault config.hardware.enableRedistributableFirmware);
  };
}
