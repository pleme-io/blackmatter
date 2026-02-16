# modules/darwin/blackmatter/profiles/macos/vfkit/default.nix
# Manages vfkit VMs on macOS (Apple Virtualization.framework)
# Supports two-disk architecture: ephemeral root (from nix store) + persistent data
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.vfkit;

  vmModule = types.submodule {
    options = {
      cpus = mkOption {
        type = types.int;
        default = 4;
        description = "Number of virtual CPUs";
      };

      memoryMiB = mkOption {
        type = types.int;
        default = 4096;
        description = "Memory in MiB";
      };

      diskImage = mkOption {
        type = types.str;
        description = "Path to the VM root disk image (raw format)";
      };

      diskSize = mkOption {
        type = types.str;
        default = "20G";
        description = "Disk size for the VM (used for initial creation)";
      };

      sourceImage = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Nix store path to the root disk image derivation. When set, the image is synced to diskImage on activation when the source changes.";
      };

      dataImage = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to persistent data disk image. Created as a sparse file if missing. Never deleted by activation scripts.";
      };

      dataImageSize = mkOption {
        type = types.str;
        default = "20G";
        description = "Size for the persistent data disk (e.g. 20G, 40G).";
      };

      kernelPath = mkOption {
        type = types.path;
        description = "Path to the kernel (bzImage or Image)";
      };

      initrdPath = mkOption {
        type = types.path;
        description = "Path to the initrd";
      };

      kernelArgs = mkOption {
        type = types.str;
        default = "console=hvc0 root=/dev/vda";
        description = "Kernel command line arguments";
      };

      autoStart = mkOption {
        type = types.bool;
        default = true;
        description = "Start VM automatically via launchd";
      };
    };
  };

  # Generate a launchd daemon for a VM
  mkVfkitDaemon = name: vmCfg: {
    serviceConfig = {
      Label = "io.pleme.vfkit.${name}";
      ProgramArguments =
        [
          "${pkgs.vfkit}/bin/vfkit"
          "--cpus" (toString vmCfg.cpus)
          "--memory" (toString vmCfg.memoryMiB)
          "--device" "virtio-blk,path=${vmCfg.diskImage}"
        ]
        ++ lib.optionals (vmCfg.dataImage != null) [
          "--device" "virtio-blk,path=${vmCfg.dataImage}"
        ]
        ++ [
          "--device" "virtio-net,nat"
          "--device" "virtio-serial,stdio"
          "--bootloader" "linux,kernel=${vmCfg.kernelPath},initrd=${vmCfg.initrdPath},cmdline=${vmCfg.kernelArgs}"
        ];
      RunAtLoad = vmCfg.autoStart;
      KeepAlive = vmCfg.autoStart;
      StandardOutPath = "/tmp/vfkit-${name}.log";
      StandardErrorPath = "/tmp/vfkit-${name}.err";
    };
  };

  # Generate activation script for a VM (disk syncing + data disk creation)
  mkVfkitActivation = name: vmCfg: let
    vmDir = builtins.dirOf vmCfg.diskImage;
  in
    lib.optionalString (vmCfg.sourceImage != null) ''
      # vfkit-${name}: sync root disk from nix store if source changed
      VFKIT_DIR="${vmDir}"
      mkdir -p "$VFKIT_DIR"
      VFKIT_HASH_FILE="$VFKIT_DIR/.source-hash"
      VFKIT_CURRENT=""
      [ -f "$VFKIT_HASH_FILE" ] && VFKIT_CURRENT=$(cat "$VFKIT_HASH_FILE")
      if [ "${vmCfg.sourceImage}" != "$VFKIT_CURRENT" ]; then
        echo "vfkit-${name}: syncing root disk from nix store..."
        cp "${vmCfg.sourceImage}/nixos.img" "${vmCfg.diskImage}"
        chmod 644 "${vmCfg.diskImage}"
        echo "${vmCfg.sourceImage}" > "$VFKIT_HASH_FILE"
      else
        echo "vfkit-${name}: root disk up to date"
      fi
    ''
    + lib.optionalString (vmCfg.dataImage != null) ''
      # vfkit-${name}: ensure persistent data disk exists
      if [ ! -f "${vmCfg.dataImage}" ]; then
        echo "vfkit-${name}: creating data disk (${vmCfg.dataImageSize})..."
        ${pkgs.coreutils}/bin/truncate -s ${vmCfg.dataImageSize} "${vmCfg.dataImage}"
      else
        echo "vfkit-${name}: data disk exists"
      fi
    '';

  # Generate shell script wrappers for VM management
  mkVfkitScripts = name: vmCfg: let
    daemonLabel = "io.pleme.vfkit.${name}";
  in [
    (pkgs.writeShellScriptBin "vfkit-${name}-start" ''
      echo "Starting vfkit VM: ${name}"
      sudo launchctl kickstart system/${daemonLabel}
    '')
    (pkgs.writeShellScriptBin "vfkit-${name}-stop" ''
      echo "Stopping vfkit VM: ${name}"
      sudo launchctl kill SIGTERM system/${daemonLabel}
    '')
    (pkgs.writeShellScriptBin "vfkit-${name}-status" ''
      if sudo launchctl print system/${daemonLabel} 2>/dev/null | grep -q "state = running"; then
        echo "VM ${name}: running"
      else
        echo "VM ${name}: stopped"
      fi
    '')
    (pkgs.writeShellScriptBin "vfkit-${name}-log" ''
      tail -f /tmp/vfkit-${name}.log
    '')
  ];
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          vfkit = {
            enable = mkEnableOption "vfkit VM management";

            vms = mkOption {
              type = types.attrsOf vmModule;
              default = {};
              description = "VMs to manage with vfkit";
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Create launchd daemons for each VM (prefixed with vfkit-)
    launchd.daemons = lib.mapAttrs' (name: vmCfg:
      lib.nameValuePair "vfkit-${name}" (mkVfkitDaemon name vmCfg)
    ) cfg.vms;

    # Add vfkit binary and management scripts to system packages
    environment.systemPackages =
      [pkgs.vfkit]
      ++ (lib.concatLists (lib.mapAttrsToList mkVfkitScripts cfg.vms));

    # Activation script: sync root disks from nix store, create data disks
    system.activationScripts.postActivation.text = mkAfter (
      lib.concatStringsSep "\n" (lib.mapAttrsToList mkVfkitActivation cfg.vms)
    );
  };
}
