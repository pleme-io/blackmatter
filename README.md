# blackmatter

Modular NixOS/nix-darwin/home-manager configuration framework.

## Overview

Blackmatter is the top-level aggregator that pulls in all `blackmatter-*` component repos and exposes them as unified flake outputs. It imports every extracted component module, composes overlays (sops-nix, claude-code, fenix-based tools), and defines profiles that select which components to enable.

User-specific data (names, IPs, secrets) belongs in the `nix` repo, not here.

## Flake Outputs

- `homeManagerModules.blackmatter` -- imports core modules + all component repos
- `darwinModules.blackmatter` -- macOS system module (profiles, DNS, nix config, tailscale)
- `nixosModules.blackmatter` -- NixOS system module (profiles, security, services, k3s, tailscale)
- `overlays.combined` -- composed overlay (sops-nix, claude-code, ghostty, zoekt-mcp, codesearch)

## Usage

```nix
{
  inputs.blackmatter = {
    url = "github:pleme-io/blackmatter";
    inputs.nixpkgs.follows = "nixpkgs";
    # Follow ALL sub-inputs to avoid duplicate closures
    inputs.blackmatter-nvim.follows = "blackmatter-nvim";
    inputs.blackmatter-shell.follows = "blackmatter-shell";
    # ... (see pleme-io/CLAUDE.md for the full list)
  };
}
```

Then in your home-manager config:

```nix
imports = [ inputs.blackmatter.homeManagerModules.blackmatter ];
```

## Structure

- `modules/home-manager/blackmatter/` -- core HM components (git, ssh, themes, profiles)
- `modules/darwin/blackmatter/` -- Darwin system config
- `modules/nixos/blackmatter/` -- NixOS system config
- `overlays/` -- local overlay fixes
- `lib/` -- shared helpers (plugin-helper)
