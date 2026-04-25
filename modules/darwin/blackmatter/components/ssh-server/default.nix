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

    quietLogin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Silence SSH login banners — suppress the MOTD and "Last login"
        line so `ssh <node>` lands directly at a prompt with no chatter.
        Maps to sshd_config `PrintMotd no` + `PrintLastLog no`. Defaults
        to true; flip to false on any node that should keep the standard
        login banner. Same option name + semantics as the NixOS side so
        a single `blackmatter.components.sshServer.quietLogin` value
        works on every fleet node regardless of platform.
      '';
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
          ++ (lib.optional cfg.quietLogin "PrintMotd no")
          ++ (lib.optional cfg.quietLogin "PrintLastLog no")
          ++ (lib.optional (cfg.acceptEnv != [])
            "AcceptEnv ${lib.concatStringsSep " " cfg.acceptEnv}")
        );
      };
    } // lib.listToAttrs (map (user: {
      name = "ssh/nix_authorized_keys.d/${user}";
      value = {
        text = lib.concatStringsSep "\n" cfg.authorizedKeys;
      };
    }) cfg.users);

    # ── Enable sshd + set login shells via bm-darwin-setup ──────
    system.activationScripts.postActivation.text = let
      bin = "${pkgs.bm-darwin-setup}/bin/bm-darwin-setup";
      setShell = user: ''
        ${bin} shell set ${user} /run/current-system/sw/bin/blzsh
      '';
    in ''
      ${bin} ssh enable
      ${lib.concatMapStringsSep "\n" setShell cfg.users}
    '';
  };
}
