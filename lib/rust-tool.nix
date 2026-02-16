# ============================================================================
# RUST TOOL BUILDER - High-Level Abstraction for CLI Tools
# ============================================================================
# Similar to rust-service.nix but for standalone CLI tools
#
# Usage in tool flake.nix:
#   let rustTool = import "${nexus}/nix/lib/rust-tool.nix" { inherit pkgs system crate2nix nexusDeploy; };
#   in rustTool {
#     toolName = "pvortex";
#     src = ./.;
#   }
#
# This returns complete flake outputs: packages, devShells, apps

{ pkgs
, system
, crate2nix
, nexusDeploy ? null
}:

{ toolName
, src
, description ? "${toolName} - Rust CLI tool"
, buildInputs ? []
, nativeBuildInputs ? []
, extraDevInputs ? []
, devEnvVars ? {}
, cargoNix ? src + "/Cargo.nix"
, registryBase ? "ghcr.io/pleme-io"
, enableRelease ? true  # Enable build/push/release apps
}:

let
  # Import centralized Attic configuration
  atticConfig = import ./attic-config.nix;

  # Default tokens (shared with services)
  defaultAtticToken = atticConfig.token;
  defaultGhcrToken = "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";

  # Standard build inputs for Rust tools
  defaultBuildInputs = with pkgs; [ openssl postgresql ];
  allBuildInputs = defaultBuildInputs ++ buildInputs;

  # Standard native build inputs for Rust tools
  defaultNativeBuildInputs = with pkgs; [ pkg-config cmake perl ];
  allNativeBuildInputs = defaultNativeBuildInputs ++ nativeBuildInputs;

  # Generate Cargo.nix from Cargo.lock using crate2nix
  generatedCargoNix = pkgs.stdenv.mkDerivation {
    name = "${toolName}-cargo-nix";
    inherit src;
    buildInputs = [ crate2nix ];
    buildPhase = ''
      ${crate2nix}/bin/crate2nix generate -f "$src/Cargo.toml" -o "$out/Cargo.nix"
    '';
    installPhase = "true";
  };

  # Use provided Cargo.nix or generate it
  finalCargoNix =
    if builtins.pathExists cargoNix
    then cargoNix
    else generatedCargoNix + "/Cargo.nix";

  # Build the Rust tool using crate2nix
  cargoNixBuild = (pkgs.callPackage finalCargoNix {
    defaultCrateOverrides = pkgs.defaultCrateOverrides // {
      ${toolName} = attrs: {
        inherit buildInputs;
        nativeBuildInputs = allNativeBuildInputs;
      };
    };
  }).workspaceMembers.${toolName}.build;

  # Create a minimal container image
  toolImage = pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/pleme-io/${toolName}";
    tag = "latest";
    contents = [ cargoNixBuild pkgs.cacert ];
    config = {
      Cmd = [ "${cargoNixBuild}/bin/${toolName}" ];
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
    };
  };

in
{
  packages = {
    default = cargoNixBuild;
    ${toolName} = cargoNixBuild;
    "${toolName}-image" = toolImage;
  };

  devShells = {
    default = pkgs.mkShell {
      name = "${toolName}-dev";

      buildInputs = allBuildInputs ++ extraDevInputs ++ (with pkgs; [
        # Rust toolchain
        rustc
        cargo
        rustfmt
        clippy
        rust-analyzer

        # Development tools
        crate2nix
      ]);

      nativeBuildInputs = allNativeBuildInputs;

      shellHook = ''
        echo "🔧 ${toolName} development environment"
        echo "Rust: $(rustc --version)"
        echo ""
        echo "Available commands:"
        echo "  cargo build    - Build the tool"
        echo "  cargo test     - Run tests"
        echo "  cargo run      - Run the tool"
        echo "  crate2nix generate  - Regenerate Cargo.nix"
        echo ""

        ${builtins.concatStringsSep "\n" (
          pkgs.lib.mapAttrsToList (name: value: "export ${name}=${value}") devEnvVars
        )}
      '';
    };
  };

  apps = {
    default = {
      type = "app";
      program = "${cargoNixBuild}/bin/${toolName}";
    };
    ${toolName} = {
      type = "app";
      program = "${cargoNixBuild}/bin/${toolName}";
    };

    # Update Cargo dependencies and regenerate Cargo.nix
    update-cargo-nix = {
      type = "app";
      program = toString (pkgs.writeShellScript "${toolName}-update-cargo-nix" ''
        set -euo pipefail

        echo "🔄 Updating Cargo dependencies and regenerating Cargo.nix..."

        # Find working directory
        if [ -f "flake.nix" ] && grep -q "${toolName}" flake.nix 2>/dev/null; then
          WORK_DIR="$PWD"
        else
          REPO_ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
          # Try multiple possible locations
          if [ -d "$REPO_ROOT/pkgs/tools/${toolName}" ]; then
            WORK_DIR="$REPO_ROOT/pkgs/tools/${toolName}"
          else
            WORK_DIR="$REPO_ROOT/pkgs/tools/rust/${toolName}"
          fi
        fi

        cd "$WORK_DIR"

        # Update Cargo dependencies
        echo "📦 Running cargo update..."
        ${pkgs.cargo}/bin/cargo update

        # Regenerate Cargo.nix
        echo "🔧 Regenerating Cargo.nix with crate2nix..."
        ${crate2nix}/bin/crate2nix generate -f Cargo.toml -o Cargo.nix

        echo ""
        echo "✅ Cargo.lock and Cargo.nix updated successfully"
        echo ""
        echo "📝 Next steps:"
        echo "   1. Review changes: git diff Cargo.lock Cargo.nix"
        echo "   2. Test build: nix build"
        echo "   3. Commit: git add Cargo.lock Cargo.nix && git commit -m 'Update Cargo dependencies'"
      '');
    };
  } // (
    if enableRelease
    then {
      # Build Docker image and push to GitHub Packages
      build = {
        type = "app";
        program = toString (pkgs.writeShellScript "${toolName}-build" ''
          set -euo pipefail

          # Export default tokens if not already set
          export ATTIC_TOKEN=''${ATTIC_TOKEN:-"${defaultAtticToken}"}
          export GITHUB_TOKEN=''${GITHUB_TOKEN:-"${defaultGhcrToken}"}

          echo "🔨 Building ${toolName} Docker image..."

          # Find working directory
          if [ -f "flake.nix" ] && grep -q "${toolName}" flake.nix 2>/dev/null; then
            WORK_DIR="$PWD"
          else
            REPO_ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
            # Try multiple possible locations
            if [ -d "$REPO_ROOT/pkgs/tools/${toolName}" ]; then
              WORK_DIR="$REPO_ROOT/pkgs/tools/${toolName}"
            else
              WORK_DIR="$REPO_ROOT/pkgs/tools/rust/${toolName}"
            fi
          fi

          cd "$WORK_DIR"

          # Auto-generate Cargo.nix if it doesn't exist
          if [ ! -f "Cargo.nix" ]; then
            echo "📦 Cargo.nix not found, generating..."
            ${crate2nix}/bin/crate2nix generate -f Cargo.toml -o Cargo.nix
            echo "✅ Generated Cargo.nix"
            echo ""
          fi

          # Build the Docker image
          echo "Building ${toolName}-image..."
          nix build .#${toolName}-image

          # Create result symlink
          if [ -L "result" ]; then
            echo "✅ Docker image built successfully: ./result"
          else
            echo "❌ Build failed - no result symlink created"
            exit 1
          fi

          echo ""
          echo "📦 Next step: Run 'nix run .#push' to push to GitHub Packages"
        '');
      };

      # Push Docker image to GitHub Packages
      push = {
        type = "app";
        program = toString (pkgs.writeShellScript "${toolName}-push" ''
          set -euo pipefail

          # Export default tokens if not already set
          export ATTIC_TOKEN=''${ATTIC_TOKEN:-"${defaultAtticToken}"}
          export GITHUB_TOKEN=''${GITHUB_TOKEN:-"${defaultGhcrToken}"}

          echo "📤 Pushing ${toolName} to GitHub Packages..."

          if [ -z "$GITHUB_TOKEN" ]; then
            echo "❌ Error: GITHUB_TOKEN not available"
            exit 1
          fi

          # Find working directory
          if [ -f "flake.nix" ] && grep -q "${toolName}" flake.nix 2>/dev/null; then
            WORK_DIR="$PWD"
          else
            REPO_ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
            # Try multiple possible locations
            if [ -d "$REPO_ROOT/pkgs/tools/${toolName}" ]; then
              WORK_DIR="$REPO_ROOT/pkgs/tools/${toolName}"
            else
              WORK_DIR="$REPO_ROOT/pkgs/tools/rust/${toolName}"
            fi
          fi

          cd "$WORK_DIR"

          # Check if result exists
          if [ ! -L "result" ]; then
            echo "❌ Error: No Docker image found. Run 'nix run .#build' first"
            exit 1
          fi

          # Get git SHA for tagging
          GIT_SHA=$(${pkgs.git}/bin/git rev-parse --short HEAD)

          # Registry details
          REGISTRY="${registryBase}/${toolName}"

          echo "Loading image into Docker..."
          docker load < result

          echo "Tagging image..."
          # Get the loaded image name from docker load output
          IMAGE_NAME=$(docker load < result 2>&1 | grep -oP 'Loaded image: \K.*')

          docker tag "$IMAGE_NAME" "$REGISTRY:$GIT_SHA"
          docker tag "$IMAGE_NAME" "$REGISTRY:latest"

          echo "Logging in to GitHub Packages..."
          echo "$GITHUB_TOKEN" | docker login ghcr.io -u $USER --password-stdin

          echo "Pushing $REGISTRY:$GIT_SHA..."
          docker push "$REGISTRY:$GIT_SHA"

          echo "Pushing $REGISTRY:latest..."
          docker push "$REGISTRY:latest"

          echo ""
          echo "✅ Successfully pushed ${toolName} to GitHub Packages!"
          echo "   - $REGISTRY:$GIT_SHA"
          echo "   - $REGISTRY:latest"
          echo ""
          echo "📥 Pull with: docker pull $REGISTRY:latest"
        '');
      };

      # Full release workflow (build + push)
      release = {
        type = "app";
        program = toString (pkgs.writeShellScript "${toolName}-release" ''
          set -euo pipefail

          # Export default tokens if not already set
          export ATTIC_TOKEN=''${ATTIC_TOKEN:-"${defaultAtticToken}"}
          export GITHUB_TOKEN=''${GITHUB_TOKEN:-"${defaultGhcrToken}"}

          echo "🚀 ${toolName} Release Workflow"
          echo "$(printf '=%.0s' {1..50})"
          echo ""

          # Step 1: Build
          echo "Step 1/2: Building Docker image..."
          nix run .#build

          # Step 2: Push
          echo ""
          echo "Step 2/2: Pushing to GitHub Packages..."
          nix run .#push

          echo ""
          echo "✅ Release complete!"
          echo ""
          echo "The ${toolName} tool is now available at:"
          echo "  docker pull ${registryBase}/${toolName}:latest"
        '');
      };
    }
    else {}
  );
}
