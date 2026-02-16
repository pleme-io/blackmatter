{ config, lib, pkgs, ... }:

let
  cfg = config.blackmatter.components.nix-builder;
in
{
  options.blackmatter.components.nix-builder = {
    enable = lib.mkEnableOption "Nix remote builder server (accepts builds from other machines)";

    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Maximum number of concurrent build jobs this builder can handle";
    };

    supportedSystems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "x86_64-linux" "aarch64-linux" ];
      description = "System architectures this builder can build for";
    };

    speedFactor = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Relative speed of this builder (higher = faster)";
    };

    sshPort = lib.mkOption {
      type = lib.types.int;
      default = 22;
      description = "SSH port for remote builders to connect on";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys authorized to use this builder";
      example = [ "ssh-ed25519 AAAAC3... user@machine" ];
    };

    nixSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        # Allow builders to use substituters to avoid rebuilding
        builders-use-substitutes = true;

        # Enable flakes and nix command
        experimental-features = [ "nix-command" "flakes" ];

        # Optimize build performance
        cores = 0; # Use all available cores
        max-jobs = "auto";
      };
      description = "Additional Nix settings for the builder";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure Nix daemon is enabled
    nix.enable = true;

    # Apply Nix settings
    nix.settings = cfg.nixSettings // {
      # Allow this machine to be used as a remote builder
      trusted-users = [ "root" "@wheel" ];
    };

    # Configure SSH for remote builds
    services.openssh = {
      enable = true;
      ports = [ cfg.sshPort ];
      settings = {
        # Allow root login for Nix builds (required for remote builders)
        # Use mkForce since this is security-critical for builder functionality
        PermitRootLogin = lib.mkForce "prohibit-password";

        # Note: PasswordAuthentication is NOT set here to avoid conflicts with profile-level settings.
        # Root user has authorizedKeys configured, so key-based auth works regardless.

        # Performance optimizations for Nix builds
        Compression = lib.mkDefault true;
        TCPKeepAlive = lib.mkDefault true;
      };
    };

    # Add authorized keys for root user (needed for Nix remote builds)
    users.users.root.openssh.authorizedKeys.keys = cfg.authorizedKeys;

    # Ensure Nix store has enough space
    # (builders need significant storage for build artifacts)
    systemd.services.nix-daemon.serviceConfig = {
      # Increase limits for heavy build loads
      LimitNOFILE = 1048576;
      LimitNPROC = 1048576;
    };

    # Open firewall for SSH if enabled
    networking.firewall.allowedTCPPorts = [ cfg.sshPort ];

    # Log configuration for debugging
    system.activationScripts.nix-builder-info = ''
      echo "Nix Builder Configuration:"
      echo "  Max Jobs: ${toString cfg.maxJobs}"
      echo "  Supported Systems: ${lib.concatStringsSep ", " cfg.supportedSystems}"
      echo "  SSH Port: ${toString cfg.sshPort}"
      echo "  Authorized Keys: ${toString (builtins.length cfg.authorizedKeys)} keys configured"
    '';
  };
}
