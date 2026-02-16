# Enhanced profile system with composition and feature flags
{ lib, config, ... }:
with lib;
rec {
  # Profile feature flags
  features = {
    # Core system features
    system = {
      boot = mkEnableOption "boot configuration";
      networking = mkEnableOption "networking setup";
      bluetooth = mkEnableOption "bluetooth support";
      sound = mkEnableOption "audio support";
      printing = mkEnableOption "printing support";
      virtualization = mkEnableOption "virtualization support";
      docker = mkEnableOption "docker support";
      security = mkEnableOption "security hardening";
    };

    # Desktop features
    desktop = {
      xserver = mkEnableOption "X server support";
      wayland = mkEnableOption "Wayland support";
      displayManager = mkEnableOption "display manager";
      nvidia = mkEnableOption "NVIDIA GPU support";
      amd = mkEnableOption "AMD GPU support";
      intel = mkEnableOption "Intel GPU support";
    };

    # Development features
    development = {
      languages = mkEnableOption "programming languages";
      tools = mkEnableOption "development tools";
      databases = mkEnableOption "database services";
      containers = mkEnableOption "container tools";
    };

    # Service features
    services = {
      ssh = mkEnableOption "SSH server";
      monitoring = mkEnableOption "system monitoring";
      backup = mkEnableOption "backup services";
      networking = mkEnableOption "network services";
    };
  };

  # Profile templates
  templates = {
    # Minimal base profile
    base = {
      system = {
        boot = true;
        networking = true;
        security = true;
      };
      services = {
        ssh = true;
      };
    };

    # Desktop workstation
    desktop = {
      inherit (templates.base) services;
      system = templates.base.system // {
        sound = true;
        bluetooth = true;
      };
      desktop = {
        wayland = true;
        displayManager = true;
      };
      development = {
        tools = true;
      };
    };

    # Development machine
    developer = {
      inherit (templates.desktop) desktop services;
      system = templates.desktop.system // {
        docker = true;
        virtualization = true;
      };
      development = {
        languages = true;
        tools = true;
        databases = true;
        containers = true;
      };
    };

    # Server
    server = {
      inherit (templates.base) system;
      services = {
        ssh = true;
        monitoring = true;
        backup = true;
        networking = true;
      };
    };
  };

  # Profile builder
  mkProfile = { name, description, template ? "base", features ? {}, overrides ? {} }:
    let
      # Start with template
      baseFeatures = templates.${template} or templates.base;

      # Merge with custom features
      mergedFeatures = recursiveUpdate baseFeatures features;

      # Apply overrides
      finalFeatures = recursiveUpdate mergedFeatures overrides;
    in {
      options.blackmatter.profiles.${name} = {
        enable = mkEnableOption description;

        # Expose feature flags for fine-tuning
        features = mkOption {
          type = types.attrs;
          default = finalFeatures;
          description = "Feature flags for ${name} profile";
        };

        # Allow feature overrides
        overrides = mkOption {
          type = types.attrs;
          default = {};
          description = "Feature overrides for ${name} profile";
          example = {
            system.bluetooth = false;
            desktop.nvidia = true;
          };
        };
      };

      config = let
        cfg = config.blackmatter.profiles.${name};
        # Merge base features with user overrides
        activeFeatures = recursiveUpdate cfg.features cfg.overrides;
      in mkIf cfg.enable {
        # Apply system features
        ${optionalString (activeFeatures.system.boot or false) ''
          imports = [ ../profiles/${name}/boot ];
        ''}

        # Networking
        ${optionalString (activeFeatures.system.networking or false) ''
          imports = [ ../profiles/${name}/networking ];
        ''}

        # Add more feature applications...
      };
    };

  # Profile composition helper
  composeProfiles = profiles:
    let
      # Collect all enabled features from active profiles
      enabledFeatures = foldl' (acc: profile:
        if config.blackmatter.profiles.${profile}.enable or false then
          recursiveUpdate acc config.blackmatter.profiles.${profile}.features
        else
          acc
      ) {} profiles;
    in enabledFeatures;

  # Profile inheritance helper
  inheritProfile = { child, parent, additionalFeatures ? {}, overrides ? {} }:
    mkProfile {
      name = child;
      description = "${child} profile (inherits from ${parent})";
      template = parent;
      features = additionalFeatures;
      inherit overrides;
    };

  # Feature dependency resolver
  resolveFeatureDependencies = features:
    let
      dependencies = {
        # Wayland requires display manager
        desktop.wayland = [ "desktop.displayManager" ];
        # Docker requires virtualization
        system.docker = [ "system.virtualization" ];
        # Databases require networking
        development.databases = [ "system.networking" ];
      };

      # Recursively enable dependencies
      enableDeps = feat: path:
        let
          deps = dependencies.${path} or [];
          depPaths = map (d: setAttrByPath (splitString "." d) true) deps;
        in foldl' recursiveUpdate feat depPaths;
    in
      foldl' (acc: path:
        if getAttrFromPath (splitString "." path) features == true then
          enableDeps acc path
        else
          acc
      ) features (attrNames dependencies);

  # Profile validation
  validateProfile = name: features:
    let
      conflicts = [
        # Can't have both X and Wayland as primary
        {
          condition = features.desktop.xserver or false && features.desktop.wayland or false;
          message = "Profile ${name}: Cannot enable both xserver and wayland as primary display server";
        }
        # Can't enable multiple GPU vendors
        {
          condition = (count (x: x) [
            (features.desktop.nvidia or false)
            (features.desktop.amd or false)
            (features.desktop.intel or false)
          ]) > 1;
          message = "Profile ${name}: Cannot enable multiple GPU vendors";
        }
      ];

      errors = filter (c: c.condition) conflicts;
    in
      if errors != [] then
        throw (concatStringsSep "\n" (map (e: e.message) errors))
      else
        features;

  # Helper to create feature-based options
  mkFeatureOptions = features:
    mapAttrsRecursive (path: value:
      if isBool value then
        mkEnableOption (concatStringsSep " " path)
      else
        value
    ) features;

  # Apply features to configuration
  applyFeatures = name: features: {
    # System features
    boot = mkIf (features.system.boot or false) {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    networking = mkIf (features.system.networking or false) {
      networkmanager.enable = mkDefault true;
      firewall.enable = mkDefault true;
    };

    hardware.bluetooth = mkIf (features.system.bluetooth or false) {
      enable = true;
      powerOnBoot = true;
    };

    # Desktop features
    services.xserver = mkIf (features.desktop.xserver or false) {
      enable = true;
    };

    programs.hyprland = mkIf (features.desktop.wayland or false) {
      enable = true;
    };

    # Development features
    virtualisation.docker = mkIf (features.system.docker or false) {
      enable = true;
    };

    # Add more feature applications...
  };
}
