# modules/darwin/blackmatter/profiles/macos/nix/default.nix
{
  config,
  lib,
  inputs ? null,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.nix;

  # Builder submodule type
  builderType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this remote builder";
      };

      hostname = mkOption {
        type = types.str;
        description = "SSH hostname for the remote builder";
      };

      ipAddress = mkOption {
        type = types.str;
        description = "IP address of the remote builder";
      };

      port = mkOption {
        type = types.int;
        default = 22;
        description = "SSH port for the remote builder";
      };

      maxJobs = mkOption {
        type = types.int;
        default = 8;
        description = "Maximum parallel jobs on remote builder";
      };

      speedFactor = mkOption {
        type = types.int;
        default = 1;
        description = "Relative speed factor (higher = faster, used for job scheduling)";
      };

      systems = mkOption {
        type = types.listOf types.str;
        default = ["x86_64-linux" "aarch64-linux"];
        description = "Supported build systems on remote builder";
      };
    };
  };

  # Filter enabled builders
  enabledBuilders = filter (b: b.enable) (attrValues cfg.remoteBuilders);

in {
  imports = [
    ../../../../../shared/nix-performance.nix
    ../../../../../shared/nix-binary.nix
  ];

  options = {
    blackmatter = {
      profiles = {
        macos = {
          nix = {
            enable = mkEnableOption "enable Nix configuration for Darwin";

            performance = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable high-performance Nix configuration";
              };

              atticCache = {
                enable = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Enable Attic cache via Istio gateway";
                };

                enablePush = mkOption {
                  type = types.bool;
                  default = true;
                  description = "Automatically push built artifacts to cache";
                };
              };
            };

            # Multiple remote builders support
            remoteBuilders = mkOption {
              type = types.attrsOf builderType;
              default = {
                # plo - Primary builder (always on, high performance server)
                plo = {
                  enable = true;
                  hostname = "plo";
                  ipAddress = "192.168.50.3";
                  port = 22;
                  maxJobs = 16;
                  speedFactor = 4;
                  systems = ["x86_64-linux"];
                };

                # zek - Secondary builder (laptop, may not be available)
                zek = {
                  enable = false;  # Disabled by default - use plo
                  hostname = "zek";
                  ipAddress = "192.168.50.47";
                  port = 22;
                  maxJobs = 8;
                  speedFactor = 2;
                  systems = ["x86_64-linux"];
                };

                # k8s - Kubernetes-based builder
                k8s = {
                  enable = false;  # Disabled by default - use plo
                  hostname = "nix-builder";
                  ipAddress = "192.168.50.100";
                  port = 2222;
                  maxJobs = 8;
                  speedFactor = 1;
                  systems = ["x86_64-linux" "aarch64-linux"];
                };
              };
              description = "Remote Linux builders for cross-platform builds";
            };

            # SSH key configuration
            sshKeyPath = mkOption {
              type = types.str;
              default = "/var/root/.ssh/nix_builder_ed25519";
              description = "Path to SSH key for remote builder authentication";
            };

            userSshKeyPath = mkOption {
              type = types.str;
              default = "/Users/drzzln/.ssh/nix_builder_ed25519";
              description = "User SSH key path to copy from during activation";
            };

            trustedUsers = mkOption {
              type = types.listOf types.str;
              default = ["root" "@admin" "drzzln"];
              description = "List of trusted Nix users";
            };

            # Docker cleanup
            dockerCleanup = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description = "Enable periodic Docker cleanup (prune unused images, volumes, containers)";
              };

              interval = mkOption {
                type = types.attrs;
                default = { Weekday = 7; Hour = 11; Minute = 0; };
                description = "Docker cleanup interval (LaunchDaemon format). Default: Sundays at 11 AM.";
              };
            };

            # Nix binary variant selection
            binary = {
              variant = mkOption {
                type = types.enum ["nixpkgs-stable" "nixpkgs-latest" "nixpkgs-git"];
                default = "nixpkgs-stable";
                description = ''
                  Which Nix binary variant to use. See nix.binary.variant for details.
                  This is a convenience wrapper for the shared nix.binary module.
                '';
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Delegate Nix binary variant to shared module
    nix.binary.variant = cfg.binary.variant;

    # Enable high-performance Nix configuration
    nix.performance = mkIf cfg.performance.enable {
      enable = true;
      atticCache = {
        enable = cfg.performance.atticCache.enable;
        enablePush = cfg.performance.atticCache.enablePush;
      };
    };

    # Darwin-specific nix settings
    nix.settings = {
      sandbox = false; # Required for Darwin
      trusted-users = cfg.trustedUsers;
    };

    # Configure remote builders for Linux builds
    nix.buildMachines = map (builder: {
      hostName = builder.hostname;
      sshUser = "root";
      sshKey = cfg.sshKeyPath;
      systems = builder.systems;
      maxJobs = builder.maxJobs;
      speedFactor = builder.speedFactor;
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
    }) enabledBuilders;

    nix.distributedBuilds = (length enabledBuilders) > 0;

    # System-wide SSH configuration for all enabled builders
    programs.ssh.extraConfig = concatStringsSep "\n" (map (builder: ''
      Host ${builder.hostname}
          HostName ${builder.ipAddress}
          Port ${toString builder.port}
          User root
          IdentityFile ${cfg.sshKeyPath}
          StrictHostKeyChecking no
          UserKnownHostsFile /dev/null
    '') enabledBuilders);

    # Docker cleanup daemon - prunes unused images, volumes, and containers
    launchd.daemons.docker-cleanup = mkIf cfg.dockerCleanup.enable {
      serviceConfig = {
        Label = "org.nixos.docker-cleanup";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/bin/wait4path /usr/local/bin/docker && /usr/local/bin/docker system prune -af --volumes 2>&1 | /usr/bin/logger -t docker-cleanup"
        ];
        StartCalendarInterval = cfg.dockerCleanup.interval;
        RunAtLoad = false;
        StandardErrorPath = "/tmp/docker-cleanup.err";
      };
    };

    # Automatically copy SSH key for remote builder on activation
    system.activationScripts.postActivation.text = mkIf ((length enabledBuilders) > 0) (mkAfter ''
      echo "Setting up nix-builder SSH key..."

      # Create /var/root/.ssh directory if it doesn't exist
      if [ ! -d /var/root/.ssh ]; then
        mkdir -p /var/root/.ssh
        chmod 700 /var/root/.ssh
      fi

      # Copy SSH keys from user directory if they exist
      if [ -f ${cfg.userSshKeyPath} ]; then
        cp ${cfg.userSshKeyPath}* /var/root/.ssh/ 2>/dev/null || true
        chmod 600 /var/root/.ssh/nix_builder_ed25519 2>/dev/null || true
        chmod 644 /var/root/.ssh/nix_builder_ed25519.pub 2>/dev/null || true
        echo "✅ nix-builder SSH key copied to /var/root/.ssh/"
      else
        echo "⚠️  nix-builder SSH key not found at ${cfg.userSshKeyPath}"
        echo "   Generate it with: ssh-keygen -t ed25519 -f ~/.ssh/nix_builder_ed25519 -C 'nix-builder@mac'"
      fi

      echo "Enabled remote builders:"
      ${concatStringsSep "\n" (map (b: ''echo "  - ${b.hostname} (${b.ipAddress}:${toString b.port}) - ${toString b.maxJobs} jobs"'') enabledBuilders)}
    '');
  };
}
