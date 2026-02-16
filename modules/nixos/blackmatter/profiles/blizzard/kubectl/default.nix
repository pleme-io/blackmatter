# modules/nixos/blackmatter/profiles/blizzard/kubectl/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.kubectl;

  # Helper scripts for quick cluster switching
  mkClusterScript = name: pkgs.writeScriptBin "k${name}" ''
    #!${pkgs.bash}/bin/bash
    ${pkgs.kubectl}/bin/kubectl config use-context ${name} > /dev/null 2>&1
    ${pkgs.kubectl}/bin/kubectl "$@"
  '';
in {
  options = {
    blackmatter = {
      profiles = {
        blizzard = {
          kubectl = {
            enable = mkEnableOption "enable kubectl and Kubernetes CLI configuration";

            kubeconfig = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Full kubeconfig YAML content. If null, uses k3s default kubeconfig.";
            };

            clusters = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "List of cluster names to create quick-switch scripts for (e.g., kzek, kplo)";
              example = ["zek" "plo" "plo-tunnel"];
            };

            enableAliases = mkOption {
              type = types.bool;
              default = true;
              description = "Enable kubectl shell aliases";
            };

            defaultEditor = mkOption {
              type = types.str;
              default = "nvim";
              description = "Default editor for kubectl (KUBE_EDITOR)";
            };

            packages = mkOption {
              type = types.listOf types.package;
              default = with pkgs; [
                kubectl
                kubernetes-helm
                k9s
                fluxcd
                kubectx
                stern
                kubecolor
                kube-score
                kubectl-tree
              ];
              description = "Kubernetes-related packages to install";
            };

            kubeconfigUser = mkOption {
              type = types.str;
              default = "luis";
              description = "User to setup kubeconfig for";
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Install kubectl and related tools
    environment.systemPackages = cfg.packages ++ (map mkClusterScript cfg.clusters);

    # Set KUBECONFIG environment variable
    environment.variables = {
      KUBECONFIG = "$HOME/.kube/config";
      KUBE_EDITOR = cfg.defaultEditor;
    };

    # Add kubectl shell aliases
    environment.shellAliases = mkIf cfg.enableAliases ({
      k = "kubectl";
      kgp = "kubectl get pods";
      kgs = "kubectl get svc";
      kgn = "kubectl get nodes";
      kaf = "kubectl apply -f";
      kdel = "kubectl delete";
      klog = "kubectl logs";
      kexec = "kubectl exec -it";
      kctx = "kubectl config current-context";
    } // (listToAttrs (map (cluster: {
      name = "kctx-${cluster}";
      value = "kubectl config use-context ${cluster}";
    }) cfg.clusters)) // (listToAttrs (map (cluster: {
      name = "k${cluster}-nodes";
      value = "k${cluster} get nodes";
    }) cfg.clusters)));

    # Setup kubeconfig if provided, otherwise let k3s module handle it
    systemd.services.kubectl-kubeconfig-setup = mkIf (cfg.kubeconfig != null) (let
      # Check if k3s is enabled in this system
      k3sEnabled = config.blackmatter.profiles.blizzard.k3s.enable or false;
    in {
      description = "Setup kubectl kubeconfig with custom contexts";
      after = optionals k3sEnabled [ "k3s.service" ];
      requires = optionals k3sEnabled [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        path = [ pkgs.coreutils ];
        ExecStart = pkgs.writeShellScript "setup-kubectl-kubeconfig" ''
          # Wait for k3s if it exists and is active
          if systemctl is-active --quiet k3s.service 2>/dev/null; then
            while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
              echo "Waiting for k3s to generate kubeconfig..."
              sleep 2
            done
          fi

          # Setup for the specified user
          if id -u ${cfg.kubeconfigUser} >/dev/null 2>&1; then
            # Get home directory from /etc/passwd
            USER_HOME=$(grep "^${cfg.kubeconfigUser}:" /etc/passwd | cut -d: -f6)
            if [ -z "$USER_HOME" ]; then
              echo "Could not find home directory for user ${cfg.kubeconfigUser}"
              exit 1
            fi

            mkdir -p "$USER_HOME/.kube"

            cat > "$USER_HOME/.kube/config" <<'EOF'
${cfg.kubeconfig}
EOF

            chown ${cfg.kubeconfigUser}:users "$USER_HOME/.kube/config"
            chmod 600 "$USER_HOME/.kube/config"
            echo "kubectl kubeconfig setup for user ${cfg.kubeconfigUser} at $USER_HOME/.kube/config"
          fi
        '';
      };
    });
  };
}
