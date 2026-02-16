# modules/darwin/blackmatter/profiles/macos/kubectl/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.kubectl;

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
        macos = {
          kubectl = {
            enable = mkEnableOption "enable kubectl and Kubernetes CLI configuration";

            kubeconfig = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Full kubeconfig YAML content. If null, no kubeconfig will be managed.";
            };

            clusters = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "List of cluster names to create quick-switch scripts for (e.g., kzek, kplo)";
              example = ["zek" "plo"];
            };

            enableAliases = mkOption {
              type = types.bool;
              default = true;
              description = "Enable kubectl shell aliases";
            };

            enableCompletion = mkOption {
              type = types.bool;
              default = true;
              description = "Enable kubectl shell completion";
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
              ];
              description = "Kubernetes-related packages to install";
            };

            homeManagerUser = mkOption {
              type = types.str;
              default = "drzzln";
              description = "Username for home-manager kubectl configuration";
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
    };

    # Create the kubeconfig file in the user's home directory via home-manager
    home-manager.users.${cfg.homeManagerUser} = mkIf (cfg.kubeconfig != null) {
      # Create the kubeconfig with proper text content
      home.file.".kube/config" = {
        force = true;  # Overwrite existing file without backup
        text = cfg.kubeconfig;
      };

      # Set KUBE_EDITOR
      home.sessionVariables = {
        KUBE_EDITOR = cfg.defaultEditor;
      };

      # Add kubectl aliases
      programs.zsh.shellAliases = mkIf cfg.enableAliases {
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
      }) cfg.clusters));

      # Enable kubectl completion for zsh
      programs.zsh.initExtra = mkIf cfg.enableCompletion ''
        # Kubectl completion
        if command -v kubectl &> /dev/null; then
          source <(kubectl completion zsh)
          complete -F __start_kubectl k
        fi

        # Show current k8s context in prompt (optional)
        kube_context() {
          local context=$(kubectl config current-context 2>/dev/null)
          if [ -n "$context" ]; then
            echo " ⎈ $context"
          fi
        }
      '';
    };
  };
}
