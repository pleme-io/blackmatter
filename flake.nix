{
  description = "Blackmatter - modular NixOS/Darwin/Home-Manager configuration framework";

  inputs = {
    # Core nixpkgs (pinned to same rev as pleme-io/nix)
    nixpkgs.url = "github:NixOS/nixpkgs/d6c71932130818840fc8fe9509cf50be8c64634f";

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
      url = "git+ssh://git@github.com/pleme-io/blackmatter-nvim.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-shell = {
      url = "git+ssh://git@github.com/pleme-io/blackmatter-shell.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-claude = {
      url = "git+ssh://git@github.com/pleme-io/blackmatter-claude.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-desktop = {
      url = "git+ssh://git@github.com/pleme-io/blackmatter-desktop.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-security = {
      url = "git+ssh://git@github.com/pleme-io/blackmatter-security.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    blackmatter-kubernetes = {
      url = "git+ssh://git@github.com/pleme-io/blackmatter-kubernetes.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, ... } @ inputs: {
    # Home-Manager module — imports core blackmatter + all extracted components
    homeManagerModules.blackmatter = { ... }: {
      imports = [
        # Core: profiles, themes, inline components (ghostty, git, ssh, etc.)
        ./modules/home-manager/blackmatter
        # Extracted component repos
        inputs.blackmatter-nvim.homeManagerModules.default
        inputs.blackmatter-shell.homeManagerModules.default
        inputs.blackmatter-claude.homeManagerModules.default
        inputs.blackmatter-desktop.homeManagerModules.default
        inputs.blackmatter-security.homeManagerModules.default
        inputs.blackmatter-kubernetes.homeManagerModules.default
      ];
    };

    # Darwin system module (macOS profiles, DNS, nix config, etc.)
    darwinModules.blackmatter = import ./modules/darwin/blackmatter;

    # NixOS system module (NixOS profiles + NixOS-specific components)
    nixosModules.blackmatter = import ./modules/nixos/blackmatter;

    # Combined overlay (sops-nix, claude-code, fenix-based tools, + local fixes)
    overlays = let
      zoektMcpOverlay = import ./overlays/zoekt-mcp.nix {inherit inputs;};
      codesearchOverlay = import ./overlays/codesearch.nix {inherit inputs;};
      myOverlays = [
        inputs.sops-nix.overlays.default
        inputs.claude-code.overlays.default
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
      shellHelper = import ./lib/shell-helper.nix;
    };
  };
}
