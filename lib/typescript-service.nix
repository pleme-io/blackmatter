# ============================================================================
# TYPESCRIPT SERVICE BUILDER - High-Level Abstraction for TypeScript Microservices
# ============================================================================
# Mirrors the pattern of rust-service.nix and go-service.nix for TypeScript services
#
# Usage in service flake.nix:
#   let tsService = import "${nix-lib}/typescript-service.nix" {
#     inherit system nixpkgs dream2nix;
#     nexusDeploy = nexus.packages.${system}.nexus-deploy;
#   };
#   in tsService {
#     serviceName = "novaskyn-api";
#     src = ./.;
#   }
#
{ nixpkgs, system, dream2nix, nexusDeploy }: {
  serviceName,
  src,
  description ? "${serviceName} - TypeScript Service",
  nodeVersion ? "20",
  buildInputs ? [],
  containerPorts ? {
    http = 3000;
    health = 3001;
    metrics = 9090;
  },
  productName ? "infrastructure",
  namespace ? "${productName}-staging",
  cluster ? "orion",
  buildCommand ? "npm run build",
  startCommand ? "node dist/main.js",
}: let
  pkgs = import nixpkgs { inherit system; };

  # Use dream2nix for TypeScript/Node.js builds
  nodeProject = dream2nix.lib.makeFlakeOutputs {
    systemsFromFile = [ system ];
    config.projectRoot = src;
    source = src;
    settings = [{
      subsystemInfo.nodejs = nodeVersion;
    }];
  };

  # Fallback to simple npm-based build if dream2nix fails
  nodeBinary = pkgs.stdenv.mkDerivation {
    pname = serviceName;
    version = "0.1.0";
    inherit src;

    nativeBuildInputs = with pkgs; [
      nodejs_20
      nodePackages.npm
      nodePackages.typescript
    ] ++ buildInputs;

    buildPhase = ''
      export HOME=$TMPDIR
      npm ci --ignore-scripts
      ${buildCommand}
    '';

    installPhase = ''
      mkdir -p $out/app
      cp -r dist node_modules package.json $out/app/

      mkdir -p $out/bin
      cat > $out/bin/${serviceName} <<EOF
      #!/bin/sh
      cd $out/app
      exec ${pkgs.nodejs_20}/bin/node dist/main.js "\$@"
      EOF
      chmod +x $out/bin/${serviceName}
    '';
  };

  # Build multi-arch Docker images
  mkDockerImage = arch: pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/pleme-io/${serviceName}";
    tag = "latest";
    architecture = arch;

    contents = [
      nodeBinary
      pkgs.nodejs_20
      pkgs.cacert
      pkgs.tzdata
    ];

    config = {
      Cmd = [ "${nodeBinary}/bin/${serviceName}" ];
      ExposedPorts = builtins.mapAttrs (name: port: {}) containerPorts;
      WorkingDir = "${nodeBinary}/app";
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "NODE_ENV=production"
        "PORT=${toString containerPorts.http}"
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
    default = nodeBinary;
    inherit dockerImage-amd64 dockerImage-arm64;
  };

  # Development shell
  devShells.default = pkgs.mkShell {
    buildInputs = with pkgs; [
      nodejs_20
      nodePackages.npm
      nodePackages.typescript
      nodePackages.typescript-language-server
      nodePackages.prettier
      nodePackages.eslint
      kubectl
    ] ++ buildInputs;

    shellHook = ''
      echo "TypeScript development environment for ${serviceName}"
      echo "Node.js version: $(node --version)"
      echo "Available commands:"
      echo "  npm install    - Install dependencies"
      echo "  npm run build  - Build the project"
      echo "  npm run dev    - Start development server"
      echo "  npm test       - Run tests"
    '';
  };

  # Apps for CI/CD workflow
  apps = {
    default = {
      type = "app";
      program = "${nodeBinary}/bin/${serviceName}";
    };

    # Build both images
    build = {
      type = "app";
      program = toString (pkgs.writeShellScript "build-${serviceName}" ''
        set -euo pipefail
        echo "Building ${serviceName} for amd64 and arm64..."
        nix build .#dockerImage-amd64
        nix build .#dockerImage-arm64
        echo "Build complete"
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
        echo "Pushed to GHCR"
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
        echo "Deployment complete"
      '');
    };

    # Complete release: build + push + deploy
    release = {
      type = "app";
      program = toString (pkgs.writeShellScript "release-${serviceName}" ''
        set -euo pipefail
        echo "Releasing ${serviceName}..."
        nix run .#build
        nix run .#push
        nix run .#deploy
        echo "Release complete"
      '');
    };

    # Run tests
    test = {
      type = "app";
      program = toString (pkgs.writeShellScript "test-${serviceName}" ''
        set -euo pipefail
        cd ${src}
        npm ci --ignore-scripts
        npm test
      '');
    };
  };
}
