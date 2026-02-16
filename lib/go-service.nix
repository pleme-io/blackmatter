# ============================================================================
# GO SERVICE BUILDER - High-Level Abstraction for Go Microservices
# ============================================================================
# Mirrors the pattern of rust-service.nix for Go-based services
#
# Usage in service flake.nix:
#   let goService = import "${nix-lib}/go-service.nix" {
#     inherit system nixpkgs;
#     nixLib = nix-lib;
#     nexusDeploy = nexus.packages.${system}.nexus-deploy;
#   };
#   in goService {
#     serviceName = "pangea-operator";
#     src = ./.;
#     goVersion = "1.23";
#   }
#
{ nixpkgs, system, nixLib, nexusDeploy }: {
  serviceName,
  src,
  description ? "${serviceName} - Go Service",
  goVersion ? "1.24",
  vendorHash,
  buildInputs ? [],
  ldflags ? [],
  containerPorts ? {
    metrics = 8080;
    health = 8081;
  },
  productName ? "infrastructure",
  namespace ? "${productName}-staging",
  cluster ? "orion",
}: let
  pkgs = import nixpkgs { inherit system; };

  # Build the Go binary using buildGoModule
  goBinary = pkgs.buildGoModule {
    pname = serviceName;
    version = "0.1.0";
    inherit src vendorHash;

    inherit buildInputs ldflags;

    # Use specified Go version
    nativeBuildInputs = [ pkgs."go_${builtins.replaceStrings ["."] ["_"] goVersion}" ];

    # Standard Go build flags (using env attribute set for Nix compatibility)
    env = {
      CGO_ENABLED = if buildInputs == [] then "0" else "1";
    };
  };

  # Build multi-arch Docker images
  mkDockerImage = arch: pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/pleme-io/${serviceName}";
    tag = "latest";
    architecture = arch;

    contents = [
      goBinary
      pkgs.cacert  # For HTTPS
      pkgs.tzdata  # For timezone support
    ];

    config = {
      Cmd = [ "${goBinary}/bin/${serviceName}" ];
      ExposedPorts = builtins.mapAttrs (name: port: {}) containerPorts;
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  };

  dockerImage-amd64 = mkDockerImage "amd64";
  dockerImage-arm64 = mkDockerImage "arm64";

  # Deployment manifest path
  manifestPath = "../../nix/k8s/clusters/${cluster}/${namespace}/${serviceName}/deployment.yaml";

in {
  # Package outputs
  packages = {
    default = goBinary;
    inherit dockerImage-amd64 dockerImage-arm64;
  };

  # Development shell
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      go
      gopls
      gotools
      go-tools
      golangci-lint
      kubectl
      kubernetes-helm
    ] ++ buildInputs;

    shellHook = ''
      echo "Go ${goVersion} development environment for ${serviceName}"
      echo "Available commands:"
      echo "  go build -o bin/${serviceName} ."
      echo "  go test ./..."
      echo "  golangci-lint run"
    '';
  };

  # Apps for CI/CD workflow
  apps = {
    default = {
      type = "app";
      program = "${goBinary}/bin/${serviceName}";
    };

    # Build both images and push to Attic cache
    build = {
      type = "app";
      program = toString (pkgs.writeShellScript "build-${serviceName}" ''
        set -euo pipefail
        echo "Building ${serviceName} for amd64 and arm64..."
        nix build .#dockerImage-amd64
        nix build .#dockerImage-arm64
        echo "✅ Build complete"
      '');
    };

    # Push images to GHCR using nexus-deploy
    push = {
      type = "app";
      program = toString (pkgs.writeShellScript "push-${serviceName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy push \
          --registry ghcr.io/pleme-io/${serviceName} \
          --retries 10 \
          --tag $(git rev-parse HEAD)
        echo "✅ Pushed to GHCR"
      '');
    };

    # Full deployment workflow using nexus-deploy
    deploy = {
      type = "app";
      program = toString (pkgs.writeShellScript "deploy-${serviceName}" ''
        set -euo pipefail
        ${nexusDeploy}/bin/nexus-deploy deploy \
          --manifest ${manifestPath} \
          --registry ghcr.io/pleme-io/${serviceName} \
          --watch \
          --timeout 10m
        echo "✅ Deployment complete"
      '');
    };

    # Complete release: build + push + deploy
    release = {
      type = "app";
      program = toString (pkgs.writeShellScript "release-${serviceName}" ''
        set -euo pipefail
        echo "🚀 Releasing ${serviceName}..."
        nix run .#build
        nix run .#push
        nix run .#deploy
        echo "✅ Release complete"
      '');
    };
  };
}
