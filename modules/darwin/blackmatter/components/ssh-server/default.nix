# blackmatter.components.sshServer — macOS SSH server (Remote Login)
#
# Enables the macOS built-in SSH server via launchd and manages
# authorized_keys for key-based access. Works with the system sshd
# (not a separate openssh build).
#
# Usage:
#   blackmatter.components.sshServer = {
#     enable = true;
#     authorizedKeys = [ "ssh-ed25519 AAAA... user@machine" ];
#   };
{ config, lib, pkgs, ... }:

let
  cfg = config.blackmatter.components.sshServer;

  # Build authorized_keys content from the key list
  authorizedKeysContent = lib.concatStringsSep "\n" cfg.authorizedKeys;
in
{
  options.blackmatter.components.sshServer = {
    enable = lib.mkEnableOption "SSH server (Remote Login) for incoming connections";

    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "SSH public keys authorized to connect to this machine";
      example = [ "ssh-ed25519 AAAAC3... user@peer" ];
    };

    permitPasswordAuth = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow password authentication (default: key-only)";
    };

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Users allowed to receive SSH connections. Each user gets the
        authorizedKeys installed to their ~/.ssh/authorized_keys.
        If empty, keys are installed for the primary user only.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable macOS Remote Login (sshd) and install authorized_keys
    # on activation. Uses systemsetup to enable the system sshd.
    system.activationScripts.postActivation.text = let
      # Build the sshd config file content declaratively — overwrite on each rebuild
      sshdConfigContent = lib.concatStringsSep "\n" (
        (lib.optional (!cfg.permitPasswordAuth) "PasswordAuthentication no")
        ++ [ "AcceptEnv TERM TERMINFO TERMINFO_DIRS COLORTERM" ]
      );
      sshdConfig = ''
        # Write blackmatter sshd config (idempotent — full overwrite)
        cat > /etc/ssh/sshd_config.d/100-blackmatter.conf <<'BMSSHD'
${sshdConfigContent}
BMSSHD
      '';
      installKeys = user: ''
        # Install authorized_keys for ${user}
        _bm_ssh_home=$(eval echo "~${user}")
        if [ -d "$_bm_ssh_home" ]; then
          mkdir -p "$_bm_ssh_home/.ssh"
          chmod 700 "$_bm_ssh_home/.ssh"
          cat > "$_bm_ssh_home/.ssh/authorized_keys" <<'BMKEYS'
${authorizedKeysContent}
BMKEYS
          chmod 600 "$_bm_ssh_home/.ssh/authorized_keys"
          chown -R ${user} "$_bm_ssh_home/.ssh" 2>/dev/null || true
        fi
      '';
      userList = cfg.users;
    in ''
      # blackmatter.components.sshServer — enable Remote Login
      echo "enabling SSH server (Remote Login)..."

      # Modern macOS (13+): use launchctl to load the system sshd.
      # Falls back to systemsetup for older versions.
      if ! /bin/launchctl print system/com.openssh.sshd &>/dev/null; then
        /bin/launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null \
          || /usr/sbin/systemsetup -setremotelogin on 2>/dev/null \
          || echo "warning: could not enable Remote Login"
      fi

      ${sshdConfig}

      ${lib.concatMapStringsSep "\n" installKeys userList}
    '';
  };
}
