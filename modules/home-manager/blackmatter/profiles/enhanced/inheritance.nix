# Profile Inheritance Examples
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.blackmatter.profiles;
  
  # Base profile type
  mkBaseProfile = { name, description, defaultFeatures }:
    {
      enable = mkEnableOption description;
      features = defaultFeatures;
      packages = mkOption {
        type = types.listOf types.package;
        default = [];
        description = "Additional packages for ${name} profile";
      };
    };
  
  # Inherit and extend a profile
  inheritProfile = { parent, child, extraFeatures ? {}, extraPackages ? [] }:
    let
      parentCfg = cfg.${parent};
    in mkIf cfg.${child}.enable {
      # Enable parent profile
      blackmatter.profiles.${parent} = {
        enable = true;
        features = recursiveUpdate parentCfg.features extraFeatures;
        packages = parentCfg.packages ++ extraPackages;
      };
    };
in {
  options.blackmatter.profiles = {
    # Base profiles that others can inherit from
    base = mkBaseProfile {
      name = "base";
      description = "Base profile with minimal setup";
      defaultFeatures = {
        shell = {
          type = "bash";
          starship = false;
          tmux = false;
        };
        development = {
          neovim = false;
          languages = [];
          tools = [ "git" ];
        };
      };
    };
    
    # Power user inherits from base
    powerUser = mkBaseProfile {
      name = "powerUser";
      description = "Power user profile (inherits from base)";
      defaultFeatures = {};
    };
    
    # Developer inherits from power user
    developer = mkBaseProfile {
      name = "developer";
      description = "Developer profile (inherits from powerUser)";
      defaultFeatures = {};
    };
    
    # Data scientist inherits from developer
    dataScientist = mkBaseProfile {
      name = "dataScientist";
      description = "Data scientist profile (inherits from developer)";
      defaultFeatures = {};
    };
    
    # DevOps engineer inherits from developer
    devopsEngineer = mkBaseProfile {
      name = "devopsEngineer";
      description = "DevOps engineer profile (inherits from developer)";
      defaultFeatures = {};
    };
    
    # Security researcher inherits from power user
    securityResearcher = mkBaseProfile {
      name = "securityResearcher";
      description = "Security researcher profile (inherits from powerUser)";
      defaultFeatures = {};
    };
  };
  
  config = mkMerge [
    # Base profile - minimal setup
    (mkIf cfg.base.enable {
      blackmatter.components = {
        shell = {
          enable = true;
          packages.enable = false; # Minimal packages only
        };
      };
      
      home.packages = with pkgs; [
        coreutils
        findutils
        gnugrep
        gnused
        gawk
      ] ++ cfg.base.packages;
      
      home.sessionVariables = {
        EDITOR = "vim";
      };
    })
    
    # Power User - inherits from base, adds power tools
    (inheritProfile {
      parent = "base";
      child = "powerUser";
      extraFeatures = {
        shell = {
          type = "zsh";
          starship = true;
          tmux = true;
        };
        development = {
          tools = [ "git" "fzf" "ripgrep" "fd" "bat" "eza" ];
        };
      };
      extraPackages = with pkgs; [
        htop
        ncdu
        duf
        tldr
        httpie
        jq
        yq
      ];
    })
    
    # Developer - inherits from powerUser, adds dev tools
    (inheritProfile {
      parent = "powerUser";
      child = "developer";
      extraFeatures = {
        development = {
          neovim = true;
          languages = [ "nix" "bash" "python" ];
          tools = [ "git" "fzf" "ripgrep" "fd" "bat" "eza" "lazygit" "gh" ];
        };
        packages = {
          categories = [ "utilities" "encryption" ];
        };
      };
      extraPackages = with pkgs; [
        gnumake
        gcc
        gdb
        strace
        ltrace
        valgrind
        docker-compose
        dive
        lazydocker
      ];
    })
    
    # Data Scientist - inherits from developer, adds data tools
    (inheritProfile {
      parent = "developer";
      child = "dataScientist";
      extraFeatures = {
        development = {
          languages = [ "python" "r" "julia" ];
        };
        packages = {
          ecosystems = [ "datascience" ];
        };
      };
      extraPackages = with pkgs; [
        jupyter
        python3Packages.pandas
        python3Packages.numpy
        python3Packages.matplotlib
        python3Packages.scikit-learn
        rPackages.tidyverse
        rPackages.ggplot2
      ];
    })
    
    # DevOps Engineer - inherits from developer, adds ops tools
    (inheritProfile {
      parent = "developer";
      child = "devopsEngineer";
      extraFeatures = {
        development = {
          languages = [ "go" "python" "bash" ];
        };
        packages = {
          ecosystems = [ "cloudInfrastructure" "devopsAutomation" ];
          categories = [ "kubernetes" "aws" "hashicorp" ];
        };
      };
      extraPackages = with pkgs; [
        kubectl
        k9s
        helm
        terraform
        ansible
        vault
        consul
        nomad
        # awscli2 # Disabled: slow test suite hangs builds
        google-cloud-sdk
        azure-cli
        prometheus
        grafana
      ];
    })
    
    # Security Researcher - inherits from powerUser, adds security tools
    (inheritProfile {
      parent = "powerUser";
      child = "securityResearcher";
      extraFeatures = {
        development = {
          languages = [ "python" "c" "rust" ];
          tools = [ "git" "fzf" "ripgrep" "hexdump" "strings" ];
        };
      };
      extraPackages = with pkgs; [
        nmap
        wireshark
        tcpdump
        john
        hashcat
        metasploit
        burpsuite
        sqlmap
        gobuster
        nikto
        radare2
        ghidra
        binwalk
        gef
      ];
    })
    
    # Helper function to show inheritance chain
    (let
      showInheritance = profile: 
        let
          inheritance = 
            if profile == "base" then "base"
            else if elem profile ["powerUser" "securityResearcher"] then "base → ${profile}"
            else if elem profile ["developer"] then "base → powerUser → ${profile}"
            else if elem profile ["dataScientist" "devopsEngineer"] then "base → powerUser → developer → ${profile}"
            else profile;
        in {
          home.file.".config/blackmatter/profile-inheritance.txt".text = ''
            Current Profile: ${profile}
            Inheritance Chain: ${inheritance}
            
            Features inherited and applied:
            ${builtins.toJSON (cfg.${profile}.features or {})}
          '';
        };
      
      activeProfile = head (filter (p: cfg.${p}.enable or false) 
        ["dataScientist" "devopsEngineer" "securityResearcher" "developer" "powerUser" "base"]);
    in mkIf (activeProfile != null) (showInheritance activeProfile))
  ];
}