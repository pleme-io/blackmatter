# Example of composed profiles
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.blackmatter.profiles;
in {
  # Gaming Desktop Profile - Composes multiple profiles
  options.blackmatter.profiles.gamingDesktop = {
    enable = mkEnableOption "Gaming desktop profile";
    
    # Which base profiles to compose
    compose = {
      useBlizzard = mkOption {
        type = types.bool;
        default = true;
        description = "Include Blizzard desktop features";
      };
      
      usePerformance = mkOption {
        type = types.bool;
        default = true;
        description = "Include performance optimizations";
      };
      
      useMultimedia = mkOption {
        type = types.bool;
        default = true;
        description = "Include multimedia features";
      };
    };
    
    # Override specific features
    overrides = {
      gpu = mkOption {
        type = types.enum [ "nvidia" "amd" "intel" ];
        default = "nvidia";
        description = "GPU vendor";
      };
      
      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Additional packages";
      };
    };
  };
  
  # Developer Workstation - Inherits from blizzard and adds dev features
  options.blackmatter.profiles.devWorkstation = {
    enable = mkEnableOption "Developer workstation profile";
    
    languages = mkOption {
      type = types.listOf types.str;
      default = [ "nix" "rust" "go" "python" "javascript" ];
      description = "Programming languages to support";
    };
    
    tools = {
      docker = mkEnableOption "Docker and container tools" // { default = true; };
      kubernetes = mkEnableOption "Kubernetes tools";
      databases = mkEnableOption "Database servers" // { default = true; };
      cloudTools = mkEnableOption "Cloud platform tools";
    };
  };
  
  # Minimal Server - Composes just the essentials
  options.blackmatter.profiles.minimalServer = {
    enable = mkEnableOption "Minimal server profile";
    
    features = {
      ssh = mkEnableOption "SSH server" // { default = true; };
      monitoring = mkEnableOption "Basic monitoring";
      firewall = mkEnableOption "Firewall" // { default = true; };
    };
  };
  
  config = mkMerge [
    # Gaming Desktop Implementation
    (mkIf cfg.gamingDesktop.enable {
      # Enable base profiles
      blackmatter.profiles.blizzard = mkIf cfg.gamingDesktop.compose.useBlizzard {
        enable = true;
        features = {
          performance.cpuGovernor = "performance";
          performance.enableGameMode = true;
          desktop.gpu = cfg.gamingDesktop.overrides.gpu;
        };
      };
      
      # Gaming-specific packages
      environment.systemPackages = with pkgs; [
        steam
        lutris
        mangohud
        gamemode
      ] ++ cfg.gamingDesktop.overrides.extraPackages;
      
      # Gaming optimizations
      boot.kernel.sysctl = {
        "vm.max_map_count" = 2147483642; # For some games
        "net.core.netdev_max_backlog" = 16384; # Network performance
      };
      
      # Enable 32-bit support for games
      hardware.graphics.enable32Bit = true;
      hardware.pulseaudio.support32Bit = true;
      
      # Steam-specific
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = false;
      };
    })
    
    # Developer Workstation Implementation
    (mkIf cfg.devWorkstation.enable {
      # Inherit from blizzard
      blackmatter.profiles.blizzard = {
        enable = true;
        features = {
          system.docker = cfg.devWorkstation.tools.docker;
          development = {
            enable = true;
            languages = cfg.devWorkstation.languages;
          };
        };
        packages.development = with pkgs; [
          # Common dev tools
          gnumake
          gcc
          gdb
          valgrind
          strace
          # ltrace # Disabled: test failures in nixpkgs
        ] ++ optionals (elem "rust" cfg.devWorkstation.languages) [
          rustc
          cargo
          rust-analyzer
          rustfmt
          clippy
        ] ++ optionals (elem "go" cfg.devWorkstation.languages) [
          go
          gopls
          delve
        ] ++ optionals (elem "python" cfg.devWorkstation.languages) [
          python3
          python3Packages.pip
          python3Packages.virtualenv
          python3Packages.ipython
        ] ++ optionals (elem "javascript" cfg.devWorkstation.languages) [
          nodejs
          nodePackages.npm
          nodePackages.yarn
          nodePackages.typescript
        ];
      };
      
      # Development services
      services = mkMerge [
        (mkIf cfg.devWorkstation.tools.docker {
          virtualisation.docker = {
            enable = true;
            enableOnBoot = true;
            autoPrune.enable = true;
          };
        })
        
        (mkIf cfg.devWorkstation.tools.kubernetes {
          # K3s for local Kubernetes
          services.k3s = {
            enable = true;
            role = "server";
          };
        })
        
        (mkIf cfg.devWorkstation.tools.databases {
          # PostgreSQL
          services.postgresql = {
            enable = true;
            package = pkgs.postgresql_15;
            enableTCPIP = true;
            authentication = ''
              local all all trust
              host all all 127.0.0.1/32 trust
            '';
          };
          
          # Redis
          services.redis.servers."dev" = {
            enable = true;
            port = 6379;
          };
        })
      ];
      
      # Development environment variables
      environment.variables = {
        EDITOR = "nvim";
        BROWSER = "firefox";
        TERMINAL = "alacritty";
      };
    })
    
    # Minimal Server Implementation
    (mkIf cfg.minimalServer.enable {
      # Disable GUI components
      services.xserver.enable = false;
      
      # Basic networking
      networking = {
        firewall.enable = cfg.minimalServer.features.firewall;
        firewall.allowedTCPPorts = mkIf cfg.minimalServer.features.ssh [ 22 ];
      };
      
      # SSH server
      services.openssh = mkIf cfg.minimalServer.features.ssh {
        enable = true;
        settings = {
          PermitRootLogin = "prohibit-password";
          PasswordAuthentication = false;
        };
      };
      
      # Basic monitoring
      services = mkIf cfg.minimalServer.features.monitoring {
        prometheus.exporters.node = {
          enable = true;
          enabledCollectors = [ "systemd" "processes" ];
        };
      };
      
      # Minimal packages
      environment.systemPackages = with pkgs; [
        vim
        tmux
        htop
        ncdu
        git
      ];
      
      # Resource limits for server
      systemd.services."user@".serviceConfig = {
        MemoryMax = "2G";
        TasksMax = "4096";
      };
    })
  ];
}