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

        ★ macOS 14+ / 26+ CONSTRAINT (load-bearing reality):
        Apple has progressively removed every non-MDM path to install a
        TCC-bearing `.mobileconfig`:
          • macOS 14: `profiles install` CLI returns "profiles tool no
            longer supports installs. Use System Settings Profiles to
            add configuration profiles."
          • macOS 15+: double-clicking the .mobileconfig in Finder routes
            to System Settings → Profiles, where the user can install
            non-TCC profiles manually.
          • macOS 26: System Settings rejects TCC-bearing profiles with
            "The profile must originate from a user approved MDM server."
        Direct TCC.db edits (sqlite3) are blocked even for root under
        SIP (TCC kext returns "authorization denied"). `tccutil` only
        supports `reset`, not `grant`. The activation script keeps the
        `profiles install` attempt and absorbs its failure with `|| echo`
        so the rebuild itself succeeds; the FDA grant simply doesn't
        land. Per-node opt-out: set this option to `false`.

        ★ CSE destination: a small pleme-io substrate primitive
        (working name `cracha-mdm`/`mado-mdm`) — Rust Axum server
        emitting Apple-signed profiles from a `TataraDomain`, one-time
        per-Mac enrollment (the one unavoidable GUI click: "Allow
        Device Management"). Once enrolled, profile pushes are silent
        and survive macOS upgrades. When that primitive lands, this
        option's install path will route through MDM and the default
        of `true` becomes meaningful again.

        ★ Workaround for fleets that need it today: System Settings →
        Privacy & Security → Full Disk Access → `+` →
        `/usr/sbin/sshd` and `/usr/libexec/sshd-keygen-wrapper` (use
        ⌘⇧G in the file picker to reach those paths). ~60 sec one-time
        per Mac.

        Defaults to true to keep the destination expressed in code,
        even though the install attempt is currently a no-op on
        macOS 14+. NixOS-side: irrelevant — Linux has no TCC, sudo
        over SSH just works.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # ── sshd config + authorized keys + FDA profile ─────────────
    # All three contributions to environment.etc are composed via
    # lib.mkMerge so the static attribute set is defined exactly
    # once (nix-darwin treats `environment.etc.x = …` and
    # `environment.etc = { x = …; }` in the same config block as
    # duplicate definitions of `environment.etc`, which is a hard
    # eval error — mkMerge sidesteps that).
    environment.etc = lib.mkMerge [
      {
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
      }
      (lib.listToAttrs (map (user: {
        name = "ssh/nix_authorized_keys.d/${user}";
        value = {
          text = lib.concatStringsSep "\n" cfg.authorizedKeys;
        };
      }) cfg.users))
      (lib.mkIf cfg.fullDiskAccess {
        # PPPC profile granting Full Disk Access to SSH-spawned
        # processes. Identifier is namespaced under
        # `io.pleme.blackmatter.*` so it never collides with user /
        # MDM-installed profiles.
        "blackmatter/profiles/remote-ssh-fda.mobileconfig" = {
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
      })
    ];

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
