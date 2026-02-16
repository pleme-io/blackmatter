# Enhanced Blizzard Profile with Feature Flags
{ config, lib, pkgs, ... }:
with lib;
let
  profileLib = import ../../lib/profiles.nix { inherit lib config; };
  cfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard = {
    enable = mkEnableOption "Blizzard desktop profile";
    
    # Feature flags with defaults
    features = {
      # Core system
      system = {
        boot = mkOption {
          type = types.bool;
          default = true;
          description = "Enable boot configuration";
        };
        networking = mkOption {
          type = types.bool;
          default = true;
          description = "Enable networking";
        };
        bluetooth = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Bluetooth support";
        };
        sound = mkOption {
          type = types.bool;
          default = true;
          description = "Enable audio support";
        };
        printing = mkOption {
          type = types.bool;
          default = false;
          description = "Enable printing support";
        };
        docker = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Docker support";
        };
      };
      
      # Desktop
      desktop = {
        type = mkOption {
          type = types.enum [ "wayland" "xorg" "both" ];
          default = "wayland";
          description = "Desktop server type";
        };
        displayManager = mkOption {
          type = types.enum [ "gdm" "sddm" "greetd" "lightdm" ];
          default = "greetd";
          description = "Display manager to use";
        };
        gpu = mkOption {
          type = types.enum [ "nvidia" "amd" "intel" "hybrid" "none" ];
          default = "nvidia";
          description = "GPU type";
        };
      };
      
      # Development
      development = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable development tools";
        };
        languages = mkOption {
          type = types.listOf types.str;
          default = [ "nix" "bash" ];
          description = "Programming languages to support";
        };
      };
      
      # Performance
      performance = {
        cpuGovernor = mkOption {
          type = types.enum [ "performance" "powersave" "ondemand" "conservative" ];
          default = "performance";
          description = "CPU frequency governor";
        };
        enableGameMode = mkOption {
          type = types.bool;
          default = false;
          description = "Enable GameMode for gaming performance";
        };
      };
    };
    
    # Package sets
    packages = {
      core = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [ vim wget git bash fontconfig ];
        description = "Core system packages";
      };
      
      desktop = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [ firefox alacritty ];
        description = "Desktop packages";
      };
      
      development = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [ ];
        description = "Development packages";
      };
      
      extra = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Additional packages";
      };
    };
  };
  
  imports = [
    # Conditionally import based on features
    (mkIf cfg.features.system.boot ../blizzard/boot)
    (mkIf cfg.features.system.networking ../blizzard/networking)
    (mkIf cfg.features.system.bluetooth ../blizzard/bluetooth)
    (mkIf cfg.features.system.sound ../blizzard/sound)
    (mkIf cfg.features.system.docker ../blizzard/docker)
    (mkIf (cfg.features.desktop.type != "none") ../blizzard/xserver)
  ];
  
  config = mkIf cfg.enable (mkMerge [
    # Core configuration always applied
    {
      console = {
        font = "Lat2-Terminus16";
        keyMap = "us";
      };
      
      # Apply performance settings
      powerManagement.cpuFreqGovernor = cfg.features.performance.cpuGovernor;
      
      # Core services
      services.dbus.enable = true;
      services.udev.enable = true;
      security.rtkit.enable = true;
      
      # Shell
      programs.zsh.enable = true;
      
      # Packages
      environment.systemPackages = cfg.packages.core ++ cfg.packages.extra;
      
      # Fonts
      fonts = {
        fontconfig.enable = true;
        fontDir.enable = true;
        enableDefaultPackages = true;
        packages = with pkgs; [
          fira-code
          fira-code-symbols
          dejavu_fonts
        ];
      };
    }
    
    # Conditional features
    (mkIf cfg.features.system.printing {
      services.printing.enable = true;
      services.printing.drivers = with pkgs; [ gutenprint hplip ];
    })
    
    # Desktop configuration
    (mkIf (cfg.features.desktop.type != "none") {
      # Common desktop settings
      services.libinput.enable = true;
      xdg.portal.enable = true;
      hardware.graphics.enable = true;
      
      environment.systemPackages = cfg.packages.desktop;
    })
    
    # Wayland-specific
    (mkIf (elem cfg.features.desktop.type [ "wayland" "both" ]) {
      programs.hyprland.enable = true;
      xdg.portal.wlr.enable = true;
      
      environment.variables = mkIf (cfg.features.desktop.gpu == "nvidia") {
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        WLR_NO_HARDWARE_CURSORS = "1";
      };
    })
    
    # X.Org-specific
    (mkIf (elem cfg.features.desktop.type [ "xorg" "both" ]) {
      services.xserver.enable = true;
    })
    
    # Display manager
    (mkMerge [
      (mkIf (cfg.features.desktop.displayManager == "greetd") {
        programs.regreet.enable = true;
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --cmd Hyprland";
            };
          };
        };
      })
      
      (mkIf (cfg.features.desktop.displayManager == "gdm") {
        services.displayManager.gdm = {
          enable = true;
          wayland = cfg.features.desktop.type == "wayland";
        };
      })
      
      (mkIf (cfg.features.desktop.displayManager == "sddm") {
        services.displayManager.sddm.enable = true;
      })
    ])
    
    # GPU configuration
    (mkMerge [
      (mkIf (cfg.features.desktop.gpu == "nvidia") {
        hardware.nvidia = {
          open = false;
          modesetting.enable = true;
          powerManagement.enable = false;
        };
        services.xserver.videoDrivers = [ "nvidia" ];
      })
      
      (mkIf (cfg.features.desktop.gpu == "amd") {
        services.xserver.videoDrivers = [ "amdgpu" ];
        hardware.graphics.extraPackages = with pkgs; [
          rocm-opencl-icd
          rocm-opencl-runtime
        ];
      })
      
      (mkIf (cfg.features.desktop.gpu == "intel") {
        services.xserver.videoDrivers = [ "modesetting" ];
        hardware.graphics.extraPackages = with pkgs; [
          intel-media-driver
          vaapiIntel
        ];
      })
    ])
    
    # Development features
    (mkIf cfg.features.development.enable {
      environment.systemPackages = cfg.packages.development;
      
      # CLI Development Environment (Round 1)
      blackmatter.development.cliEditors = {
        enable = true;
        textEditors = {
          enable = true;
          includeAdvanced = true;
          includeClassic = true;
        };
        terminalMultiplexers = {
          enable = true;
          includeModern = true;
        };
        sessionManagement.enable = true;
        ides.enable = false; # Keep lightweight for now
      };
      
      # Version Control & Git Ecosystem (Round 4)
      blackmatter.development.gitTools = {
        enable = true;
        gitTUI = {
          enable = true;
          includeModern = true;
          includeClassic = true;
        };
        gitEnhancements = {
          enable = true;
          includeFlow = true;
          includeSecurity = true;
        };
        diffTools = {
          enable = true;
          includeModern = true;
        };
        hostingPlatforms = {
          enable = true;
          includeGitHub = true;
          includeGitLab = true;
          includeOthers = false; # Keep focused
        };
        versionControlSystems.enable = false; # Git-focused for now
      };
      
      # File Management & Navigation (Round 2)
      blackmatter.productivity.fileManagement = {
        enable = true;
        fileManagers = {
          enable = true;
          includeAdvanced = true;
          includeClassic = true;
        };
        searchTools = {
          enable = true;
          includeModern = true;
          includeClassic = true;
        };
        treeViews = {
          enable = true;
          includeEnhanced = true;
        };
        navigation = {
          enable = true;
          includeJumpers = true;
        };
        fuzzyFinders.enable = true;
      };
      
      # System Monitoring & Administration (Round 3)
      blackmatter.system.monitoring = {
        enable = true;
        systemMonitors = {
          enable = true;
          includeAdvanced = true;
          includeClassic = true;
        };
        processManagement = {
          enable = true;
          includeModern = true;
        };
        diskTools = {
          enable = true;
          includeAnalyzers = true;
        };
        networkTools = {
          enable = true;
          includeSecurity = true;
          includeDownloaders = true;
        };
        systemInfo = {
          enable = true;
          includeHardware = true;
        };
        performanceTools.enable = false; # Optional - keep disabled for now
      };
      
      # Multimedia & Content Tools (Round 5)
      blackmatter.multimedia.cliTools = {
        enable = true;
        audioPlayers = {
          enable = true;
          includeAdvanced = true;
          includeGUI = true;
        };
        audioTools = {
          enable = true;
          includeConverters = true;
          includeDownloaders = true;
          includeAnalysis = true;
        };
        videoTools = {
          enable = true;
          includeProcessing = true;
          includeAnalysis = true;
        };
        imageTools = {
          enable = true;
          includeProcessing = true;
          includeTextArt = true;
          includeViewing = true;
        };
        documentTools = {
          enable = true;
          includeConversion = true;
          includeFormatting = true;
        };
        presentationTools.enable = false; # Optional - keep disabled for now
      };
      
      # Enable language-specific features
      programs = mkMerge (map (lang:
        mkIf (elem lang cfg.features.development.languages) (
          if lang == "rust" then { 
            # Rust-specific configuration
          } else if lang == "go" then {
            # Go-specific configuration
          } else {}
        )
      ) cfg.features.development.languages);
    })
    
    # Gaming features
    (mkIf cfg.features.performance.enableGameMode {
      programs.gamemode.enable = true;
    })
  ]);
}