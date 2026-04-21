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

    # Pleme-io native Rust apps — their flakes expose homeManagerModules.default
    # directly (see repo-forge's (defrepo …) catalog). Wired straight in without
    # a blackmatter-<app> wrapper.
    arnes = {
      url = "git+ssh://git@github.com/pleme-io/arnes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    repo-forge = {
      url = "git+ssh://git@github.com/pleme-io/repo-forge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    namimado = {
      url = "github:pleme-io/namimado";
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
    lib = inputs.nixpkgs.lib;
    forAllSystems = lib.genAttrs [
      "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"
    ];

    # ── Fleet registry ───────────────────────────────────────────────
    # Every blackmatter-* component input, keyed by short name. Used by
    # the fleet-check app to enumerate the fleet and query each repo's
    # `blackmatter.component` metadata. Keep in sync with the inputs block
    # above and .typescape.yaml → components:.
    componentInputs = {
      anvil      = inputs.blackmatter-anvil;
      android    = inputs.blackmatter-android;
      ayatsuri   = inputs.blackmatter-ayatsuri;
      claude     = inputs.blackmatter-claude;
      desktop    = inputs.blackmatter-desktop;
      ghostty    = inputs.blackmatter-ghostty;
      home       = inputs.blackmatter-home;
      kubernetes = inputs.blackmatter-kubernetes;
      macos      = inputs.blackmatter-macos;
      nvim       = inputs.blackmatter-nvim;
      opencode   = inputs.blackmatter-opencode;
      pleme      = inputs.blackmatter-pleme;
      security   = inputs.blackmatter-security;
      services   = inputs.blackmatter-services;
      shell      = inputs.blackmatter-shell;
      tailscale  = inputs.blackmatter-tailscale;
      tend       = inputs.blackmatter-tend;
      vpn        = inputs.blackmatter-vpn;
    };

    fleetReport = let
      formatLine = name: flake: let
        meta = flake.blackmatter.component or null;
        outputs = {
          hm     = flake ? homeManagerModules;
          nixos  = flake ? nixosModules;
          darwin = flake ? darwinModules;
          ovl    = flake ? overlays;
          pkg    = flake ? packages;
        };
        tag = o:
          (if o.hm then "H" else "·")
          + (if o.nixos then "N" else "·")
          + (if o.darwin then "D" else "·")
          + (if o.ovl then "O" else "·")
          + (if o.pkg then "P" else "·");
        archetype =
          if meta == null then "custom-flake"
          else meta.shortName or name;
        status = if meta == null then "custom" else "helper";
      in "  ${lib.strings.fixedWidthString 26 " " "blackmatter-${name}"}"
         + "  ${tag outputs}"
         + "  ${lib.strings.fixedWidthString 8 " " status}"
         + "  ${archetype}";
      legend = ''
          blackmatter fleet-check report
          ──────────────────────────────
          Flag string: H=homeManagerModules N=nixosModules D=darwinModules O=overlays P=packages
          Status:      helper = uses substrate/lib/blackmatter-component-flake.nix
                       custom = intentionally custom flake (see .typescape.yaml custom_flake_reason)

          Components (${toString (builtins.length (builtins.attrNames componentInputs))}):
      '';
      body = lib.concatStringsSep "\n"
        (lib.mapAttrsToList formatLine componentInputs);
    in legend + body + "\n";
  in {
    # ── Fleet audit app ──────────────────────────────────────────────
    # Run `nix run .#fleet-check` to print a per-component report.
    # Useful for catching new components that were added to inputs but
    # not registered in .typescape.yaml components: or missing helper
    # metadata.
    apps = forAllSystems (system: {
      fleet-check = {
        type = "app";
        program = toString (inputs.nixpkgs.legacyPackages.${system}.writeShellScript
          "blackmatter-fleet-check" ''
            cat <<'REPORT_EOF'
${fleetReport}REPORT_EOF
          '');
      };
    });

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
        # blackmatter-android NOT imported here — it takes pkgs as a
        # direct module arg, which triggers infinite recursion in NixOS
        # contexts that evaluate `home-manager.users.<u>._module.freeformType`
        # before pkgs is resolvable via `_module.args`. Stack
        # `inputs.blackmatter-android.homeManagerModules.default` explicitly
        # on workstations that need android tooling. Server nodes and
        # most fleet HM configs don't.
        inputs.blackmatter-macos.homeManagerModules.default
        inputs.blackmatter-services.homeManagerModules.default
        inputs.blackmatter-home.homeManagerModules.default
        inputs.arnes.homeManagerModules.default
        inputs.repo-forge.homeManagerModules.default
        inputs.namimado.homeManagerModules.default
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
