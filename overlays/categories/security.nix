# Security tool overlays
final: prev: {
  # Network security bundle
  network-security = prev.buildEnv {
    name = "network-security";
    paths = with prev; [
      nmap
      wireshark
      tcpdump
      mtr
      dig
      whois
      netcat
      socat
    ];
  };
  
  # Encryption and cryptography bundle
  crypto-tools = prev.buildEnv {
    name = "crypto-tools";
    paths = with prev; [
      gnupg
      age
      sops
      openssl
      cryptsetup
    ] ++ prev.lib.optionals (prev ? veracrypt) [
      veracrypt
    ];
  };
  
  # Password management bundle
  password-tools = prev.buildEnv {
    name = "password-tools";
    paths = with prev; [
      bitwarden-cli
      keepassxc
      pass
      gopass
      pwgen
    ] ++ prev.lib.optionals (prev ? xkcdpass) [
      xkcdpass
    ];
  };
  
  # Enhanced GnuPG with better defaults
  gnupg-enhanced = prev.gnupg.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      mkdir -p $out/share/gnupg
      cat > $out/share/gnupg/gpg.conf << 'EOF'
      # Strong defaults
      personal-cipher-preferences AES256 AES192 AES
      personal-digest-preferences SHA512 SHA384 SHA256
      personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
      default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
      cert-digest-algo SHA512
      s2k-digest-algo SHA512
      s2k-cipher-algo AES256
      charset utf-8
      keyid-format 0xlong
      with-fingerprint
      use-agent
      EOF
    '';
  });
  
  # Enhanced SSH with hardened config
  openssh-hardened = prev.openssh.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      mkdir -p $out/share/openssh
      cat > $out/share/openssh/ssh_config.hardened << 'EOF'
      # Hardened SSH client config
      Host *
        PasswordAuthentication no
        ChallengeResponseAuthentication no
        PubkeyAuthentication yes
        HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa
        KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
        ServerAliveInterval 10
        ServerAliveCountMax 3
      EOF
    '';
  });
  
  # Vulnerability scanning bundle
  vuln-scanners = prev.buildEnv {
    name = "vuln-scanners";
    paths = with prev; [
      nikto
      lynis
    ] ++ prev.lib.optionals (prev ? sqlmap) [
      sqlmap
    ] ++ prev.lib.optionals (prev ? metasploit) [
      metasploit
    ] ++ prev.lib.optionals (prev ? chkrootkit) [
      chkrootkit
    ];
  };
  
  # Container security bundle
  container-security = prev.buildEnv {
    name = "container-security";
    paths = with prev; [
      trivy
      grype
      syft
      dive
    ] ++ prev.lib.optionals (prev ? docker-bench-security) [
      docker-bench-security
    ];
  };
  
  # Log analysis bundle
  log-analysis = prev.buildEnv {
    name = "log-analysis";
    paths = with prev; [
      lnav
      multitail
    ] ++ prev.lib.optionals (prev ? logwatch) [
      logwatch
    ] ++ prev.lib.optionals (prev ? goaccess) [
      goaccess
    ];
  };
}