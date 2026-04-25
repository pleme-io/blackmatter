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

    fullDiskAccess = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install a PPPC (Privacy Preferences Policy Control) profile
        granting Full Disk Access to SSH-spawned processes (sshd +
        sshd-keygen-wrapper). Without this, `ssh -t host 'sudo
        darwin-rebuild switch ...'` fails with:

          error: permission denied when trying to update apps over SSH,
          aborting activation

        because nix-darwin's apps-installation step needs to write to
        /Applications, which macOS's TCC blocks for SSH-launched
        processes by default. Equivalent to flipping
        System Settings → General → Sharing → Remote Login →
        "Allow full disk access for remote users".

        Defaults to true so SSH-driven rebuilds (the canonical fleet
        path) just work. The profile is generated at
        /var/db/blackmatter/profiles/remote-ssh-fda.mobileconfig and
        installed via `profiles install` from the activation script.
        First install on each Mac may require a one-time approval in
        System Settings → Privacy & Security → Profiles (Apple's
        TCC consent model — unsigned profiles can't bypass it without
        MDM enrollment).

        NixOS-side: irrelevant — Linux has no TCC, sudo over SSH just
        works.
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

    # ── PPPC profile granting FDA to SSH-spawned processes ──────
    # Generated unconditionally at the same store path so subsequent
    # `profiles install` invocations are a no-op once the profile is
    # active. Identifier is namespaced under `io.pleme.blackmatter.*`
    # so we never collide with user / MDM-installed profiles.
    environment.etc."blackmatter/profiles/remote-ssh-fda.mobileconfig" = lib.mkIf cfg.fullDiskAccess {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>PayloadContent</key>
          <array>
            <dict>
              <key>PayloadDescription</key>
              <string>Grant Full Disk Access to SSH-spawned processes (sshd + sshd-keygen-wrapper) so darwin-rebuild over SSH can update /Applications.</string>
              <key>PayloadDisplayName</key>
              <string>Blackmatter — Remote SSH Full Disk Access</string>
              <key>PayloadIdentifier</key>
              <string>io.pleme.blackmatter.tcc.remote-ssh-fda.payload</string>
              <key>PayloadOrganization</key>
              <string>pleme-io</string>
              <key>PayloadType</key>
              <string>com.apple.TCC.configuration-profile-policy</string>
              <key>PayloadUUID</key>
              <string>2C3D4E5F-1A2B-4C5D-9E8F-A1B2C3D4E5F6</string>
              <key>PayloadVersion</key>
              <integer>1</integer>
              <key>Services</key>
              <dict>
                <key>SystemPolicyAllFiles</key>
                <array>
                  <dict>
                    <key>Allowed</key>
                    <true/>
                    <key>CodeRequirement</key>
                    <string>identifier "com.apple.sshd-keygen-wrapper" and anchor apple</string>
                    <key>Identifier</key>
                    <string>/usr/libexec/sshd-keygen-wrapper</string>
                    <key>IdentifierType</key>
                    <string>path</string>
                  </dict>
                  <dict>
                    <key>Allowed</key>
                    <true/>
                    <key>CodeRequirement</key>
                    <string>identifier "com.apple.sshd" and anchor apple</string>
                    <key>Identifier</key>
                    <string>/usr/sbin/sshd</string>
                    <key>IdentifierType</key>
                    <string>path</string>
                  </dict>
                </array>
              </dict>
            </dict>
          </array>
          <key>PayloadDescription</key>
          <string>Grants Full Disk Access to SSH so `darwin-rebuild` over SSH can update /Applications. Equivalent to System Settings → Sharing → Remote Login → "Allow full disk access for remote users".</string>
          <key>PayloadDisplayName</key>
          <string>Blackmatter — Remote SSH Full Disk Access</string>
          <key>PayloadIdentifier</key>
          <string>io.pleme.blackmatter.remote-ssh-fda</string>
          <key>PayloadOrganization</key>
          <string>pleme-io</string>
          <key>PayloadScope</key>
          <string>System</string>
          <key>PayloadType</key>
          <string>Configuration</string>
          <key>PayloadUUID</key>
          <string>1B2C3D4E-5F6A-4B5C-8D9E-F0A1B2C3D4E5</string>
          <key>PayloadVersion</key>
          <integer>1</integer>
        </dict>
        </plist>
      '';
    };

    # ── Enable sshd + set login shells via bm-darwin-setup ──────
    system.activationScripts.postActivation.text = let
      bin = "${pkgs.bm-darwin-setup}/bin/bm-darwin-setup";
      setShell = user: ''
        ${bin} shell set ${user} /run/current-system/sw/bin/blzsh
      '';
      installFda = lib.optionalString cfg.fullDiskAccess ''
        # Install PPPC profile granting FDA to SSH-spawned processes.
        # Idempotent: profiles list -P -all is checked for the
        # identifier; install is skipped when present, attempted when
        # absent. macOS may require user approval in System Settings
        # → Privacy & Security → Profiles for the FIRST install on a
        # given Mac (apple's TCC consent model — no MDM, no silent
        # install). Once approved the same .mobileconfig content
        # de-dupes silently on every later rebuild.
        if ! /usr/bin/profiles -P -v 2>/dev/null | grep -q "io.pleme.blackmatter.remote-ssh-fda"; then
          echo "[blackmatter-sshServer] installing remote-ssh-fda PPPC profile..."
          /usr/bin/profiles install \
            -path /etc/blackmatter/profiles/remote-ssh-fda.mobileconfig \
            2>&1 | sed 's/^/[blackmatter-sshServer] /' || \
            echo "[blackmatter-sshServer] profile install failed — open /etc/blackmatter/profiles/remote-ssh-fda.mobileconfig and approve in System Settings → Privacy & Security → Profiles"
        fi
      '';
    in ''
      ${bin} ssh enable
      ${lib.concatMapStringsSep "\n" setShell cfg.users}
      ${installFda}
    '';
  };
}
