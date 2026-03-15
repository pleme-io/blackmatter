# blackmatter.components.sshServer — macOS SSH server (Remote Login)
#
# Pure Nix configuration using nix-darwin's native SSH infrastructure:
# - environment.etc for sshd_config.d (declarative, no shell scripts)
# - /etc/ssh/nix_authorized_keys.d/ for per-user authorized keys
# - launchd plist for enabling sshd
# - users.users.*.shell for login shell
{ config, lib, pkgs, ... }:

let
  cfg = config.blackmatter.components.sshServer;
in
{
  options.blackmatter.components.sshServer = {
    enable = lib.mkEnableOption "SSH server (Remote Login) for incoming connections";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys authorized to connect to this machine.";
      example = [ "ssh-ed25519 AAAAC3... user@peer" ];
    };

    permitPasswordAuth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password authentication (default: key-only).";
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Users that should accept SSH connections with the configured
        authorized keys. Keys are written to /etc/ssh/nix_authorized_keys.d/.
      '';
    };

    acceptEnv = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "TERM" "COLORTERM" "TERM_PROGRAM" "TERMINFO" "TERMINFO_DIRS" ];
      description = "Environment variables sshd should accept from clients.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── sshd config + authorized keys (single environment.etc block) ─
    environment.etc = {
      "ssh/sshd_config.d/100-blackmatter.conf" = {
        text = lib.concatStringsSep "\n" (
          (lib.optional (!cfg.permitPasswordAuth) "PasswordAuthentication no")
          ++ (lib.optional (!cfg.permitPasswordAuth) "KbdInteractiveAuthentication no")
          ++ [ "PubkeyAuthentication yes" ]
          ++ (lib.optional (cfg.acceptEnv != [])
            "AcceptEnv ${lib.concatStringsSep " " cfg.acceptEnv}")
        );
      };
    } // lib.listToAttrs (map (user: {
      name = "ssh/nix_authorized_keys.d/${user}";
      value = {
        text = lib.concatStringsSep "\n" cfg.authorizedKeys;
        mode = "0444";
      };
    }) cfg.users);

    # ── Enable sshd via launchd ──────────────────────────────────
    # Load the system SSH daemon on activation.
    system.activationScripts.postActivation.text = ''
      if ! /bin/launchctl print system/com.openssh.sshd &>/dev/null; then
        /bin/launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
      fi
    '';
  };
}
