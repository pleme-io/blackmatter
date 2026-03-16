# blackmatter.components.sshServer — NixOS SSH server
#
# Centralized SSH server configuration for NixOS nodes. Replaces the
# scattered openssh config in blizzard/nordstorm networking modules.
#
# Usage:
#   blackmatter.components.sshServer = {
#     enable = true;
#     authorizedKeys = [ "ssh-ed25519 AAAA... user@machine" ];
#   };
{ config, lib, pkgs, ... }:

let
  cfg = config.blackmatter.components.sshServer;
in
{
  options.blackmatter.components.sshServer = {
    enable = lib.mkEnableOption "SSH server for incoming connections";

    port = lib.mkOption {
      type = lib.types.int;
      default = 22;
      description = "SSH listen port";
    };

    permitRootLogin = lib.mkOption {
      type = lib.types.str;
      default = "prohibit-password";
      description = ''
        Root login policy. Values: "yes", "no", "prohibit-password",
        "forced-commands-only". Default is key-only root access.
      '';
    };

    permitPasswordAuth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password authentication (default: key-only)";
    };

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys authorized to connect as root";
      example = [ "ssh-ed25519 AAAAC3... user@peer" ];
    };

    userKeys = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {};
      description = ''
        Per-user authorized keys. Keys are added to each user's
        openssh.authorizedKeys.keys list.
      '';
      example = { luis = [ "ssh-ed25519 AAAA... user@peer" ]; };
    };

    survivability = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Guarantee sshd resource availability under heavy load (k3s, etc.).
        Sets high CPU/IO priority and minimum memory reservation.
      '';
    };

    performance = {
      compression = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable SSH compression";
      };

      tcpKeepAlive = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable TCP keepalive";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = [ cfg.port ];
      settings = {
        PermitRootLogin = lib.mkDefault cfg.permitRootLogin;
        PasswordAuthentication = lib.mkDefault cfg.permitPasswordAuth;
        Compression = lib.mkDefault cfg.performance.compression;
        TCPKeepAlive = lib.mkDefault cfg.performance.tcpKeepAlive;
      };
    };

    # Root + per-user authorized keys (merged into single users.users definition)
    users.users = {
      root.openssh.authorizedKeys.keys = cfg.authorizedKeys;
    } // lib.mapAttrs (_user: keys: {
      openssh.authorizedKeys.keys = keys;
    }) cfg.userKeys;

    # Open firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    # Survivability: guarantee sshd resources under load
    systemd.services.sshd.serviceConfig = lib.mkIf cfg.survivability {
      CPUWeight = "10000";
      MemoryMin = "64M";
      IOWeight = "10000";
    };
  };
}
