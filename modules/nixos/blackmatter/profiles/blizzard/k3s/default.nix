# modules/nixos/blackmatter/profiles/blizzard/k3s/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.k3s;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.k3s = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable K3s Kubernetes";
    };

    role = mkOption {
      type = types.enum ["server" "agent"];
      default = "server";
      description = "K3s role (server = control plane, agent = worker)";
    };

    serverAddr = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "K3s server URL for agent to connect to (required for agent role)";
      example = "https://192.168.50.3:6443";
    };

    tokenFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to file containing K3s token for agent (required for agent role)";
      example = "/var/lib/rancher/k3s/server/node-token";
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra K3s flags";
    };

    disableComponents = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Components to disable (e.g., traefik, servicelb)";
      example = ["traefik" "servicelb"];
    };

    clusterCIDR = mkOption {
      type = types.str;
      default = "10.42.0.0/16";
      description = "Cluster CIDR for pod network";
    };

    serviceCIDR = mkOption {
      type = types.str;
      default = "10.43.0.0/16";
      description = "Service CIDR for cluster services";
    };

    clusterDNS = mkOption {
      type = types.str;
      default = "10.43.0.10";
      description = "Cluster DNS server IP";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/rancher/k3s";
      description = "K3s data directory";
    };

    kubeconfigUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Users to setup kubeconfig for";
    };

    # Remote cluster access configuration
    remoteCluster = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable remote cluster access (for nodes that don't run K3s locally)";
      };

      clusterName = mkOption {
        type = types.str;
        default = "plo";
        description = "Name of the remote cluster";
      };

      server = mkOption {
        type = types.str;
        default = "https://192.168.50.3:6443";
        description = "Remote K3s API server address";
      };

      kubeconfig = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to kubeconfig file with credentials for remote cluster";
        example = "/run/secrets/plo-kubeconfig";
      };
    };

    shellAliases = mkOption {
      type = types.attrsOf types.str;
      default = {
        k = "kubectl";
        kgp = "kubectl get pods";
        kgs = "kubectl get svc";
        kgn = "kubectl get nodes";
        kaf = "kubectl apply -f";
        kdel = "kubectl delete";
        klog = "kubectl logs";
        kexec = "kubectl exec -it";
      };
      description = "kubectl shell aliases";
    };

    packages = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        kubectl
        k9s
        kubectx
        stern
        kubecolor
        kube-score
        kubectl-tree
      ];
      description = "Additional Kubernetes tools to install";
    };

    firewall = {
      apiServerPort = mkOption {
        type = types.int;
        default = 6443;
        description = "Kubernetes API server port";
      };

      kubeletPort = mkOption {
        type = types.int;
        default = 10250;
        description = "Kubelet metrics port";
      };

      httpPort = mkOption {
        type = types.int;
        default = 80;
        description = "HTTP port for ingress";
      };

      httpsPort = mkOption {
        type = types.int;
        default = 443;
        description = "HTTPS port for ingress";
      };

      extraTCPPorts = mkOption {
        type = types.listOf types.int;
        default = [];
        description = "Extra TCP ports to open";
      };

      extraUDPPorts = mkOption {
        type = types.listOf types.int;
        default = [8472]; # VXLAN for Flannel
        description = "Extra UDP ports to open";
      };
    };

    waitForDNS = mkOption {
      type = types.bool;
      default = true;
      description = "Wait for DNS to be ready before starting K3s";
    };

    nvidia = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Configure NVIDIA runtime for containerd";
      };
    };
  };

  config = mkIf (profileCfg.enable && (cfg.enable || cfg.remoteCluster.enable)) (let
    # Automatically set role to agent if variant is agent or workstation-agent
    actualRole = if (profileCfg.variant == "agent" || profileCfg.variant == "workstation-agent")
                 then "agent"
                 else cfg.role;

    disableFlags = map (comp: "--disable ${comp}") cfg.disableComponents;

    # Agent-specific flags
    agentFlags = lib.optionals (actualRole == "agent") ([
      (lib.optionalString (cfg.serverAddr != null) "--server ${cfg.serverAddr}")
      (lib.optionalString (cfg.tokenFile != null) "--token-file ${cfg.tokenFile}")
    ]);

    setupKubeconfig = users: ''
      while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
        echo "Waiting for k3s to start..."
        sleep 2
      done

      ${lib.concatMapStrings (user: ''
        if id -u ${user} >/dev/null 2>&1; then
          # Simple: just use /home/${user} - standard Linux home directory
          USER_HOME="/home/${user}"
          mkdir -p $USER_HOME/.kube

          # Always remove old kubeconfig to ensure clean state
          rm -f $USER_HOME/.kube/config

          # Copy fresh kubeconfig from K3s
          cp /etc/rancher/k3s/k3s.yaml $USER_HOME/.kube/config
          chown -R ${user}:users $USER_HOME/.kube
          chmod 600 $USER_HOME/.kube/config

          ${pkgs.gnused}/bin/sed -i 's/127.0.0.1/localhost/g' $USER_HOME/.kube/config

          echo "✅ Kubeconfig setup for user ${user}"
        fi
      '') users}
    '';
  in {
    # Assertions for agent mode
    assertions = [
      {
        assertion = actualRole != "agent" || cfg.serverAddr != null;
        message = "k3s agent role requires serverAddr to be set";
      }
      {
        assertion = actualRole != "agent" || cfg.tokenFile != null;
        message = "k3s agent role requires tokenFile to be set";
      }
    ];

    services.k3s = {
      enable = true;
      role = actualRole;

      # Agent mode: set serverAddr and tokenFile as proper options (required by NixOS k3s module)
      serverAddr = mkIf (actualRole == "agent" && cfg.serverAddr != null) cfg.serverAddr;
      tokenFile = mkIf (actualRole == "agent" && cfg.tokenFile != null) cfg.tokenFile;

      extraFlags = lib.concatStringsSep " " (
        (if actualRole == "server" then
          disableFlags ++ [
            "--cluster-cidr ${cfg.clusterCIDR}"
            "--service-cidr ${cfg.serviceCIDR}"
            "--cluster-dns ${cfg.clusterDNS}"
            "--data-dir ${cfg.dataDir}"
          ]
        else
          [
            "--data-dir ${cfg.dataDir}"
          ]
        ) ++ cfg.extraFlags
      );
    };

    systemd.services.k3s = {
      after = ["network-online.target" "docker.service"];
      wants = ["network-online.target"];

      serviceConfig.ExecStartPre = mkIf cfg.waitForDNS (mkForce (
        pkgs.writeShellScript "k3s-pre-start" ''
          echo "Waiting for network and DNS to be ready..."
          for i in {1..30}; do
            if ${pkgs.dnsutils}/bin/nslookup registry-1.docker.io >/dev/null 2>&1; then
              echo "DNS is ready!"
              break
            fi
            echo "Waiting for DNS... ($i/30)"
            sleep 2
          done
          echo "DNS check complete, proceeding with k3s startup"
        ''
      ));

      serviceConfig.ExecStartPost = mkIf cfg.nvidia.enable (
        pkgs.writeShellScript "k3s-post-start" ''
          echo "Configuring NVIDIA runtime for containerd..."
          sleep 10

          for i in {1..30}; do
            if [ -S /run/k3s/containerd/containerd.sock ]; then
              echo "Containerd socket ready!"
              break
            fi
            echo "Waiting for containerd socket... ($i/30)"
            sleep 2
          done

          echo "NVIDIA runtime configuration complete"
        ''
      );
    };

    boot.kernelModules = ["overlay" "br_netfilter"];

    boot.kernel.sysctl = {
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
      "net.ipv4.ip_forward" = 1;
    };

    networking.firewall = {
      allowedTCPPorts = [
        cfg.firewall.apiServerPort
        cfg.firewall.kubeletPort
        cfg.firewall.httpPort
        cfg.firewall.httpsPort
      ] ++ cfg.firewall.extraTCPPorts;

      allowedUDPPorts = cfg.firewall.extraUDPPorts;

      trustedInterfaces = ["cni0" "flannel.1"];
    };

    # Local K3s kubeconfig setup (when K3s is enabled locally)
    systemd.services.k3s-kubeconfig-setup = mkIf (cfg.enable && cfg.kubeconfigUsers != []) {
      description = "Setup kubeconfig for users (local K3s)";
      after = ["k3s.service"];
      requires = ["k3s.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "setup-kubeconfig" (setupKubeconfig cfg.kubeconfigUsers);
      };
      wantedBy = ["multi-user.target"];
    };

    # Remote cluster kubeconfig setup (when remoteCluster is enabled)
    systemd.services.remote-kubeconfig-setup = mkIf (cfg.remoteCluster.enable && cfg.kubeconfigUsers != []) {
      description = "Setup kubeconfig for remote cluster access";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "setup-remote-kubeconfig" ''
          ${lib.concatMapStrings (user: ''
            if id -u ${user} >/dev/null 2>&1; then
              USER_HOME="/home/${user}"
              mkdir -p $USER_HOME/.kube

              # Always remove old kubeconfig to ensure clean state
              rm -f $USER_HOME/.kube/config

              ${if cfg.remoteCluster.kubeconfig != null then ''
                # Copy kubeconfig from provided file (e.g., sops secret)
                if [ -f "${cfg.remoteCluster.kubeconfig}" ]; then
                  cp "${cfg.remoteCluster.kubeconfig}" $USER_HOME/.kube/config
                  chown ${user}:users $USER_HOME/.kube/config
                  chmod 600 $USER_HOME/.kube/config
                  echo "✅ Remote kubeconfig setup for user ${user} from ${cfg.remoteCluster.kubeconfig}"
                else
                  echo "⚠️  Warning: Kubeconfig file not found: ${cfg.remoteCluster.kubeconfig}"
                  exit 1
                fi
              '' else ''
                echo "⚠️  Warning: remoteCluster.kubeconfig not configured for ${cfg.remoteCluster.clusterName}"
                echo "    Please set blackmatter.profiles.blizzard.k3s.remoteCluster.kubeconfig"
                exit 1
              ''}
            fi
          '') cfg.kubeconfigUsers}
        '';
      };
      wantedBy = ["multi-user.target"];
    };

    environment.shellAliases = cfg.shellAliases;
    environment.systemPackages = cfg.packages;
  });
}
