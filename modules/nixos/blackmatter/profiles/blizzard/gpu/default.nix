# modules/nixos/blackmatter/profiles/blizzard/gpu/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.gpu;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.gpu = {
    nvidia = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA GPU support";
      };

      open = mkOption {
        type = types.bool;
        default = false;
        description = "Use open-source NVIDIA drivers";
      };

      modesetting = mkOption {
        type = types.bool;
        default = true;
        description = "Enable kernel modesetting";
      };

      containerToolkit = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA container toolkit for Kubernetes/Docker";
      };

      monitoring = mkOption {
        type = types.bool;
        default = true;
        description = "Install GPU monitoring tools (nvtop)";
      };

      kernelModules = mkOption {
        type = types.listOf types.str;
        default = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
        description = "NVIDIA kernel modules to load";
      };
    };

    opengl = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable OpenGL support";
      };

      driSupport = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DRI support";
      };

      driSupport32bit = mkOption {
        type = types.bool;
        default = true;
        description = "Enable 32-bit DRI support";
      };
    };

    containerd = {
      configureNvidia = mkOption {
        type = types.bool;
        default = false;
        description = "Configure containerd with NVIDIA runtime";
      };
    };
  };

  config = mkIf (profileCfg.enable && cfg.nvidia.enable) (mkMerge [
    # Base NVIDIA configuration
    {
      hardware.graphics = {
        enable = lib.mkDefault cfg.opengl.enable;
        enable32Bit = lib.mkDefault cfg.opengl.driSupport32bit;
      };

      hardware.nvidia.open = cfg.nvidia.open;
      hardware.nvidia.modesetting.enable = cfg.nvidia.modesetting;

      boot.kernelModules = cfg.nvidia.kernelModules;
      boot.blacklistedKernelModules = ["nouveau"];

      services.xserver.videoDrivers = mkIf config.services.xserver.enable ["nvidia"];

      environment.systemPackages = mkIf cfg.nvidia.monitoring (with pkgs; [
        nvtopPackages.nvidia
      ]);
    }

    # Container toolkit support
    (mkIf cfg.nvidia.containerToolkit {
      virtualisation.docker.enable = true;
    })

    # Containerd NVIDIA runtime
    (mkIf cfg.containerd.configureNvidia {
      virtualisation.containerd = {
        enable = true;
        settings = {
          version = 2;
          plugins."io.containerd.grpc.v1.cri" = {
            containerd = {
              runtimes = {
                nvidia = {
                  runtime_type = "io.containerd.runc.v2";
                  options = {
                    BinaryName = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
                  };
                };
              };
              default_runtime_name = "nvidia";
            };
          };
        };
      };
    })
  ]);
}
