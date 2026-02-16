# System and infrastructure overlays
final: prev: {
  # System monitoring and management bundle
  system-admin = prev.buildEnv {
    name = "system-admin";
    paths = with prev; [
      htop
      btop
      iotop
      iftop
      nethogs
      sysstat
      dstat
      glances
      lsof
      ncdu
      duf
      dust
    ];
  };
  
  # Disk and filesystem tools bundle
  disk-tools = prev.buildEnv {
    name = "disk-tools";
    paths = with prev; [
      parted
      smartmontools
      hdparm
      fio
    ] ++ prev.lib.optionals (prev ? gparted) [
      gparted
    ] ++ prev.lib.optionals (prev ? gnome.gnome-disk-utility) [
      gnome.gnome-disk-utility
    ];
  };
  
  # Backup and sync tools bundle
  backup-tools = prev.buildEnv {
    name = "backup-tools";
    paths = with prev; [
      rsync
      rclone
      restic
      borgbackup
      duplicity
      syncthing
      unison
    ];
  };
  
  # Container and virtualization bundle
  container-tools = prev.buildEnv {
    name = "container-tools";
    paths = with prev; [
      docker
      docker-compose
      podman
      podman-compose
      buildah
      skopeo
      dive
    ];
  };
  
  # Enhanced systemd with aliases
  systemd-enhanced = prev.systemd.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      # Add useful systemd aliases
      mkdir -p $out/share/systemd
      cat > $out/share/systemd/aliases << 'EOF'
      alias sctl='systemctl'
      alias jctl='journalctl'
      alias sstat='systemctl status'
      alias srestart='systemctl restart'
      alias senable='systemctl enable'
      alias sdisable='systemctl disable'
      alias jfollow='journalctl -f'
      alias jboot='journalctl -b'
      EOF
    '';
  });
  
  # Infrastructure as Code bundle
  iac-tools = prev.buildEnv {
    name = "iac-tools";
    paths = with prev; [
      terraform
      terragrunt
      ansible
      ansible-lint
      packer
    ] ++ prev.lib.optionals (prev ? vagrant) [
      vagrant
    ];
  };
  
  # Cloud CLI tools bundle
  cloud-cli = prev.buildEnv {
    name = "cloud-cli";
    paths = with prev; [
      # awscli2 # Disabled: slow test suite hangs builds
      azure-cli
      google-cloud-sdk
    ] ++ prev.lib.optionals (prev ? doctl) [
      doctl
    ] ++ prev.lib.optionals (prev ? linode-cli) [
      linode-cli
    ];
  };
  
  # Service mesh and orchestration bundle
  service-mesh = prev.buildEnv {
    name = "service-mesh";
    paths = with prev; [
      kubernetes
      kubectl
      k9s
      kubernetes-helm
    ] ++ prev.lib.optionals (prev ? linkerd) [
      linkerd
    ] ++ prev.lib.optionals (prev ? istioctl) [
      istioctl
    ];
  };
  
  # Database administration bundle
  db-admin = prev.buildEnv {
    name = "db-admin";
    paths = with prev; [
      postgresql
      mysql
      redis
      mongodb-tools
      sqlitebrowser
    ] ++ prev.lib.optionals (prev ? dbeaver) [
      dbeaver
    ];
  };
}