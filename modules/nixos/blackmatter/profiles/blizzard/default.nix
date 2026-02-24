# modules/nixos/blackmatter/profiles/blizzard/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard;
in {
  imports = [
    ./virtualisation
    ./services
    ./security
    ./vpn
    ./networking
    ./bluetooth
    ./xserver
    ./sound
    ./nix
    ./nix-binary
    # Enhanced modules for full node configuration
    ./hardware
    ./networking-extended
    ./optimizations
    ./gpu
    ./cloudflared
    ./users-packages
    ./dns
    ./kubectl
    ./laptop-server
    ./server-monitoring
    ./data-persistence
    ../../../../shared/nix-performance.nix
  ];

  options = {
    blackmatter = {
      profiles = {
        blizzard = {
          enable = mkEnableOption "enable the blizzard profile";

          variant = mkOption {
            type = types.enum ["workstation" "workstation-agent" "headless-dev" "server" "agent"];
            default = "workstation";
            description = ''
              System variant preset:
              - workstation: Desktop (Hyprland) + dev tools + k3s server + balanced performance
              - workstation-agent: Desktop (Hyprland) + dev tools + k3s agent + balanced performance
              - headless-dev: CLI only + dev tools + k3s server + k3s-optimized performance
              - server: CLI only + no dev tools + k3s server + full k3s-optimized performance
              - agent: CLI only + no dev tools + k3s agent only + maximum workload performance
            '';
          };

          console = {
            keyMap = mkOption {
              type = types.str;
              default = "us";
              description = "Console keyboard layout";
              example = "br-abnt2";
            };

            font = mkOption {
              type = types.str;
              default = "Lat2-Terminus16";
              description = "Console font";
            };
          };
        };
      };
    };
  };

  config =
    mkMerge [
      # Base configuration (all variants)
      (mkIf (cfg.enable)
        {
          # Enable extracted components
          blackmatter.components.systemLimits.enable = true;
          blackmatter.components.bootTuning.enable = true;
          blackmatter.components.dockerOptimizations.enable = true;

          # Auto-set K3s role from blizzard variant
          services.blackmatter.k3s.role = lib.mkIf config.services.blackmatter.k3s.enable (
            lib.mkDefault (
              if (cfg.variant == "agent" || cfg.variant == "workstation-agent")
              then "agent"
              else "server"
            )
          );

          # Enable high-performance Nix configuration
          nix.performance.enable = true;

          console = {
            font = cfg.console.font;
            keyMap = cfg.console.keyMap;
          };

          services.dbus.enable = true;
          services.udev.enable = true;
          services.printing.enable = lib.mkDefault false;
          services.hardware.bolt.enable = lib.mkDefault false;
          services.nfs.server.enable = lib.mkDefault false;
          programs.zsh.enable = true;

          environment.systemPackages = with pkgs; [
            vim
            wget
            git
            bash
          ];
        })

      # Desktop configuration (workstation and workstation-agent variants)
      (mkIf (cfg.enable && (cfg.variant == "workstation" || cfg.variant == "workstation-agent"))
        {
          environment.variables = {
            GBM_BACKEND = "nvidia-drm";
          };
          security.rtkit.enable = true;
          services.seatd.enable = true;
          services.libinput = {enable = true;};
          xdg.portal.enable = true;
          xdg.portal.wlr.enable = true;
          hardware.nvidia.open = false;
          hardware.graphics = {
            enable = true;
          };
          environment.systemPackages = with pkgs; [
            greetd.greetd
            greetd.regreet
            greetd.tuigreet
            fontconfig
          ];
          fonts.fontconfig.enable = true;
          fonts.fontDir.enable = true;
          fonts.enableDefaultPackages = true;
          fonts.packages = with pkgs; [
            fira-code
            fira-code-symbols
            dejavu_fonts
          ];
          programs.hyprland.enable = true;
          programs.regreet.enable = true;
          services.greetd = {
            enable = true;
            settings = {
              default_session = {
                command = "
${pkgs.greetd.tuigreet}/bin/tuigreet --cmd Hyprland
";
              };
            };
          };
        })
    ];
}
