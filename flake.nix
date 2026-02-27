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
  };

  outputs = { self, ... } @ inputs: {
    # Home-Manager module — imports core blackmatter + all extracted components
    homeManagerModules.blackmatter = { ... }: {
      imports = [
        # Core: profiles, themes, inline components (git, ssh, etc.)
        ./modules/home-manager/blackmatter
        # Extracted component repos
        inputs.blackmatter-nvim.homeManagerModules.default
        inputs.blackmatter-shell.homeManagerModules.default
        inputs.blackmatter-claude.homeManagerModules.default
        inputs.blackmatter-desktop.homeManagerModules.default
        inputs.blackmatter-ghostty.homeManagerModules.default
        inputs.blackmatter-security.homeManagerModules.default
        inputs.blackmatter-kubernetes.homeManagerModules.default
        inputs.blackmatter-opencode.homeManagerModules.default
        inputs.blackmatter-services.homeManagerModules.default
      ];
    };

    # Darwin system module (macOS profiles, DNS, nix config, etc.)
    darwinModules.blackmatter = import ./modules/darwin/blackmatter;

    # NixOS system module (NixOS profiles + NixOS-specific components)
    nixosModules.blackmatter = { ... }: {
      imports = [
        ./modules/nixos/blackmatter
        inputs.blackmatter-security.nixosModules.default
        inputs.blackmatter-services.nixosModules.default
        inputs.blackmatter-kubernetes.nixosModules.k3s
      ];
    };

    # Combined overlay (sops-nix, claude-code, fenix-based tools, + local fixes)
    overlays = let
      zoektMcpOverlay = import ./overlays/zoekt-mcp.nix {inherit inputs;};
      codesearchOverlay = import ./overlays/codesearch.nix {inherit inputs;};
      myOverlays = [
        inputs.sops-nix.overlays.default
        inputs.claude-code.overlays.default
        inputs.blackmatter-ghostty.overlays.default
        zoektMcpOverlay
        codesearchOverlay
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
