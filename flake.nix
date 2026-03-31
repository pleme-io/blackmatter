{
  description = "Blackmatter - modular NixOS/Darwin/Home-Manager configuration framework";

  inputs = {
    # Core nixpkgs (branch: nixos-25.11 stable)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Secrets management (for overlay)
    sops-nix = {
      url = "github:Mic92/sops-nix/8b89f44c2cc4581e402111d928869fe7ba9f7033";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust toolchains (for zoekt-mcp + codesearch overlays)
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code overlay
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Cloud CLI overlays (tests disabled for fast builds)
    aws-cli = {
      url = "github:pleme-io/aws-cli";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gcloud = {
      url = "github:pleme-io/gcloud";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ================================================================
    # Extracted component repos
    # Each exposes homeManagerModules.default
    # ================================================================
    blackmatter-nvim = {
      url = "github:pleme-io/blackmatter-nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-shell = {
      url = "github:pleme-io/blackmatter-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.blackmatter-nvim.follows = "blackmatter-nvim";
    };
    blackmatter-claude = {
      url = "github:pleme-io/blackmatter-claude";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-desktop = {
      url = "github:pleme-io/blackmatter-desktop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-security = {
      url = "github:pleme-io/blackmatter-security";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-kubernetes = {
      url = "github:pleme-io/blackmatter-kubernetes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-services = {
      url = "github:pleme-io/blackmatter-services";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-ghostty = {
      url = "github:pleme-io/blackmatter-ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-opencode = {
      url = "github:pleme-io/blackmatter-opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-tend = {
      url = "github:pleme-io/blackmatter-tend";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-ayatsuri = {
      url = "github:pleme-io/blackmatter-ayatsuri";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-pleme = {
      url = "github:pleme-io/blackmatter-pleme";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-android = {
      url = "github:pleme-io/blackmatter-android";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.devenv.follows = "devenv";
    };
    blackmatter-macos = {
      url = "github:pleme-io/blackmatter-macos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-tailscale = {
      url = "github:pleme-io/blackmatter-tailscale";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-vpn = {
      url = "github:pleme-io/blackmatter-vpn";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-anvil = {
      url = "github:pleme-io/blackmatter-anvil";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-home = {
      url = "github:pleme-io/blackmatter-home";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake placement tool (used by home.activation to write flake.nix files)
    nix-place = {
      url = "github:pleme-io/nix-place";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Substrate (for flake-fragment-helpers option types + activation generator)
    substrate = {
      url = "github:pleme-io/substrate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin system activation tool (sshd, login shells, dscl)
    bm-darwin-setup = {
      url = "github:pleme-io/bm-darwin-setup";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... } @ inputs:
  let
    forAllSystems = inputs.nixpkgs.lib.genAttrs [
      "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
    ];
  in {
    devShells = forAllSystems (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in {
      default = inputs.devenv.lib.mkShell {
        inputs = { nixpkgs = inputs.nixpkgs; devenv = inputs.devenv; };
        inherit pkgs;
        modules = [{
          languages.nix.enable = true;
          packages = with pkgs; [ nixpkgs-fmt nil ];
          git-hooks.hooks.nixpkgs-fmt.enable = true;
        }];
      };
    });

    # Home-Manager module — imports core blackmatter + all extracted components
    homeManagerModules.blackmatter = { ... }: let
      fragmentHelpers = import "${inputs.substrate}/lib/hm/flake-fragment-helpers.nix" {
        lib = inputs.nixpkgs.lib;
      };
      claudeMdHelpers = import "${inputs.substrate}/lib/hm/claude-md-helpers.nix" {
        lib = inputs.nixpkgs.lib;
      };
    in {
      imports = [
        # Core: profiles, themes, inline components (git, ssh, etc.)
        ./modules/home-manager/blackmatter
        # Flake fragment option + activation (uses pkgs.nix-place from overlay)
        (fragmentHelpers.mkFlakeFragmentModule {})
        # CLAUDE.md composable deployment at every directory level
        (claudeMdHelpers.mkClaudeMdModule {})
        # Extracted component repos
        inputs.blackmatter-nvim.homeManagerModules.default
        inputs.blackmatter-shell.homeManagerModules.default
        inputs.blackmatter-claude.homeManagerModules.default
        inputs.blackmatter-desktop.homeManagerModules.default
        inputs.blackmatter-ghostty.homeManagerModules.default
        inputs.blackmatter-security.homeManagerModules.default
        inputs.blackmatter-kubernetes.homeManagerModules.default
        inputs.blackmatter-opencode.homeManagerModules.default
        inputs.blackmatter-tend.homeManagerModules.default
        inputs.blackmatter-ayatsuri.homeManagerModules.default
        inputs.blackmatter-pleme.homeManagerModules.default
        inputs.blackmatter-android.homeManagerModules.default
        inputs.blackmatter-macos.homeManagerModules.default
        inputs.blackmatter-services.homeManagerModules.default
        inputs.blackmatter-home.homeManagerModules.default
      ];
    };

    # Darwin system module (macOS profiles, DNS, nix config, etc.)
    darwinModules.blackmatter = { ... }: {
      imports = [
        (import ./modules/darwin/blackmatter)
        inputs.blackmatter-tailscale.darwinModules.default
        inputs.blackmatter-vpn.darwinModules.default
      ];
    };

    # NixOS system module (NixOS profiles + NixOS-specific components)
    nixosModules.blackmatter = { ... }: {
      imports = [
        ./modules/nixos/blackmatter
        inputs.blackmatter-android.nixosModules.default
        inputs.blackmatter-security.nixosModules.default
        inputs.blackmatter-services.nixosModules.default
        inputs.blackmatter-kubernetes.nixosModules.k3s
        inputs.blackmatter-kubernetes.nixosModules.kubernetes
        inputs.blackmatter-kubernetes.nixosModules.fluxcd
        inputs.blackmatter-tailscale.nixosModules.default
        inputs.blackmatter-vpn.nixosModules.default
      ];
    };

    # Combined overlay (sops-nix, claude-code, fenix-based tools, + local fixes)
    overlays = let
      zoektMcpOverlay = import ./overlays/zoekt-mcp.nix {inherit inputs;};
      codesearchOverlay = import ./overlays/codesearch.nix {inherit inputs;};
      nixPlaceOverlay = import ./overlays/nix-place.nix {inherit inputs;};
      myOverlays = [
        inputs.sops-nix.overlays.default
        inputs.claude-code.overlays.default
        inputs.aws-cli.overlays.default
        inputs.gcloud.overlays.default
        inputs.blackmatter-ghostty.overlays.default
        inputs.bm-darwin-setup.overlays.default
        zoektMcpOverlay
        codesearchOverlay
        nixPlaceOverlay
      ] ++ import ./overlays;
    in {
      combined = final: prev:
        builtins.foldl' (acc: o: acc // o final prev) {} myOverlays;
    };

    # Shared library helpers
    lib = {
      pluginHelper = import ./lib/plugin-helper.nix;
      # shellHelper lives in blackmatter-shell (canonical source)
    };
  };
}
