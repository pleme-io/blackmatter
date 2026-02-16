# ============================================================================
# RUBY TOOL BUILDER - High-Level Abstraction for Ruby CLI Tools
# ============================================================================
# Mirrors the pattern of rust-tool.nix for Ruby-based tools
#
# Usage in tool flake.nix:
#   let rubyTool = import "${nix-lib}/ruby-tool.nix" {
#     inherit system nixpkgs;
#     nixLib = nix-lib;
#     nexusDeploy = nexus.packages.${system}.nexus-deploy;
#   };
#   in rubyTool {
#     toolName = "pangea-executor";
#     src = ./.;
#     rubyVersion = "3.3";
#   }
#
{ nixpkgs, system, nixLib, nexusDeploy }: {
  toolName,
  src,
  description ? "${toolName} - Ruby CLI Tool",
  rubyVersion ? "3.3",
  gemfile,
  gemset,
  runtimeDependencies ? pkgs: [],
  entryPoint ? "bin/${toolName}",
  containerUser ? "app",
  containerWorkdir ? "/app",
  productName ? "infrastructure",
  namespace ? "${productName}-staging",
  cluster ? "orion",
}: let
  pkgs = import nixpkgs { inherit system; };

  # Select Ruby version
  ruby = pkgs."ruby_${builtins.replaceStrings ["."] ["_"] rubyVersion}";

  # Build Ruby application with bundlerApp
  rubyApp = pkgs.bundlerApp {
    pname = toolName;
    inherit gemfile gemset;
    exes = [ toolName ];
    inherit ruby;
  };

  # Collect runtime dependencies
  allRuntimeDeps = [ rubyApp ruby ] ++ (runtimeDependencies pkgs);

  # Build multi-arch Docker images
  mkDockerImage = arch: pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/pleme-io/${toolName}";
    tag = "latest";
    architecture = arch;

    contents = allRuntimeDeps ++ (with pkgs; [
      cacert
      tzdata
      coreutils
      bash
    ]);

    config = {
      Cmd = [ "${rubyApp}/bin/${toolName}" ];
      WorkingDir = containerWorkdir;
      User = containerUser;
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "PATH=/bin:/usr/bin"
      ];
    };

    # Create non-root user
    extraCommands = ''
      mkdir -p ${containerWorkdir}
      mkdir -p etc
      echo "${containerUser}:x:1000:1000::/home/${containerUser}:/bin/bash" > etc/passwd
      echo "${containerUser}:x:1000:" > etc/group
    '';
  };

  dockerImage-amd64 = mkDockerImage "amd64";
  dockerImage-arm64 = mkDockerImage "arm64";

  # Deployment manifest path
  manifestPath = "../../nix/k8s/clusters/${cluster}/${namespace}/${toolName}/deployment.yaml";

in {
  # Package outputs
  packages = {
    default = rubyApp;
    inherit dockerImage-amd64 dockerImage-arm64;
  };

  # Development shell
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      ruby
      bundler
      bundix  # For generating gemset.nix
    ] ++ (runtimeDependencies pkgs);

    shellHook = ''
      echo "Ruby ${rubyVersion} development environment for ${toolName}"
      echo "Available commands:"
      echo "  bundle install"
      echo "  bundle exec ${toolName}"
      echo "  bundix  # Update gemset.nix after Gemfile changes"
    '';
  };

  # Apps for CI/CD workflow (same pattern as Go service)
  apps = {
    default = {
      type = "app";
      program = "${rubyApp}/bin/${toolName}";
    };

    build = {
      type = "app";
      program = toString (pkgs.writeShellScript "build-${toolName}" ''
        set -euo pipefail
        echo "Building ${toolName} for amd64 and arm64..."
        nix build .#dockerImage-amd64
        nix build .#dockerImage-arm64
        echo "✅ Build complete"
      '');
    };

    push = {
      type = "app";
      program = toString (pkgs.writeShellScript "push-${toolName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy push \
          --registry ghcr.io/pleme-io/${toolName} \
          --retries 10 \
          --tag $(git rev-parse HEAD)
        echo "✅ Pushed to GHCR"
      '');
    };

    deploy = {
      type = "app";
      program = toString (pkgs.writeShellScript "deploy-${toolName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy deploy \
          --manifest ${manifestPath} \
          --registry ghcr.io/pleme-io/${toolName} \
          --watch \
          --timeout 10m
        echo "✅ Deployment complete"
      '');
    };

    release = {
      type = "app";
      program = toString (pkgs.writeShellScript "release-${toolName}" ''
        set -euo pipefail
        echo "🚀 Releasing ${toolName}..."
        nix run .#build
        nix run .#push
        nix run .#deploy
        echo "✅ Release complete"
      '');
    };
  };
}
