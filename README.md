# Blackmatter

Modular NixOS, nix-darwin, and Home Manager configuration framework. Blackmatter aggregates 15+ extracted component repositories into a single set of importable modules, provides a profile system for composing environments from base layers through desktop-specific presets, manages overlays for package fixes and tool integrations, and includes a plugin helper library for Neovim plugin management via lazy.nvim.

## Architecture

```
                         blackmatter (this repo)
                        /       |        \
               HM module    Darwin module   NixOS module
              /    |    \        |              |
         profiles  components  themes     profiles/components
            |          |
     base → presets    inline (git, ssh, env, packages)
            |
     variant overlays (hyprland, sway, cosmic, niri)

  Extracted component repos (each exposes homeManagerModules.default):
  ┌──────────────────────────────────────────────────────────────┐
  │ blackmatter-shell      blackmatter-nvim     blackmatter-claude │
  │ blackmatter-desktop    blackmatter-security blackmatter-kubernetes │
  │ blackmatter-ghostty    blackmatter-opencode blackmatter-tend │
  │ blackmatter-karakuri   blackmatter-pleme    blackmatter-macos │
  │ blackmatter-services   blackmatter-tailscale                  │
  └──────────────────────────────────────────────────────────────┘

  Overlays (folded into overlays.combined):
  ┌──────────────────────────────────────────────────────────────┐
  │ sops-nix  claude-code  fenix-based (zoekt-mcp, codesearch)  │
  │ GCC compat fixes  Python pins  package-specific build fixes  │
  │ Category overlays: development, productivity, security, system│
  └──────────────────────────────────────────────────────────────┘
```

Blackmatter itself contains no user-specific data (names, IPs, secrets). All identity and machine-specific configuration belongs in the consuming repository (typically the private `nix` repo).

## Features

- **Three module targets**: Home Manager, nix-darwin, and NixOS modules from a single flake
- **Layered profile system**: Base profiles (minimal, developer, server, desktop) compose into presets (frost, blizzard, winter, nordstorm) with optional compositor variants (Hyprland, Sway, Niri, Cosmic)
- **15 extracted component repos**: Each blackmatter-* repo is independently versioned and imported as a flake input with `nixpkgs.follows` to avoid closure duplication
- **Inline components**: Small, rarely-changing modules (git, SSH, env vars, packages, Hammerspoon) live directly in this repo
- **Overlay aggregation**: Combines sops-nix, claude-code, fenix-based tool overlays, and 12+ package fix overlays into a single `overlays.combined`
- **Plugin helper library**: Generates Neovim plugin modules from simple declarations, with lazy.nvim integration for deferred loading
- **Network topology schema**: Shared option definitions for nodes, services, and DNS mappings consumed by both Darwin and NixOS modules
- **Nord theme system**: Consistent theming via Stylix base16 integration

## Installation

Add blackmatter as a flake input. Override all sub-inputs to share nixpkgs and avoid duplicate closures:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sops-nix.url = "github:Mic92/sops-nix";
    fenix.url = "github:nix-community/fenix";
    claude-code.url = "github:sadjow/claude-code-nix";

    # Component repos (pin or follow as needed)
    blackmatter-nvim.url = "github:pleme-io/blackmatter-nvim";
    blackmatter-shell.url = "github:pleme-io/blackmatter-shell";
    blackmatter-claude.url = "github:pleme-io/blackmatter-claude";
    blackmatter-desktop.url = "github:pleme-io/blackmatter-desktop";
    blackmatter-security.url = "github:pleme-io/blackmatter-security";
    blackmatter-kubernetes.url = "github:pleme-io/blackmatter-kubernetes";
    # ... other blackmatter-* repos

    blackmatter = {
      url = "github:pleme-io/blackmatter";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.sops-nix.follows = "sops-nix";
      inputs.fenix.follows = "fenix";
      inputs.claude-code.follows = "claude-code";
      inputs.blackmatter-nvim.follows = "blackmatter-nvim";
      inputs.blackmatter-shell.follows = "blackmatter-shell";
      inputs.blackmatter-claude.follows = "blackmatter-claude";
      inputs.blackmatter-desktop.follows = "blackmatter-desktop";
      inputs.blackmatter-security.follows = "blackmatter-security";
      inputs.blackmatter-kubernetes.follows = "blackmatter-kubernetes";
    };
  };
}
```

## Usage

### Home Manager

```nix
# home.nix
{ inputs, ... }: {
  imports = [
    inputs.blackmatter.homeManagerModules.blackmatter
  ];

  # Enable a preset profile
  blackmatter.profiles.frost.enable = true;

  # Or compose from base profiles directly
  blackmatter.profiles.base.developer.enable = true;
  blackmatter.components.desktop.kitty.enable = true;
  blackmatter.components.kubernetes.enable = true;
}
```

### nix-darwin

```nix
# darwin-configuration.nix
{ inputs, ... }: {
  imports = [
    inputs.blackmatter.darwinModules.blackmatter
  ];

  blackmatter.profiles.macos = {
    enable = true;
    enableAll = true;  # or enable individual sub-modules
  };

  # Apply the combined overlay
  nixpkgs.overlays = [ inputs.blackmatter.overlays.combined ];
}
```

### NixOS

```nix
# configuration.nix
{ inputs, ... }: {
  imports = [
    inputs.blackmatter.nixosModules.blackmatter
  ];

  # NixOS profiles configure system-level services
  blackmatter.profiles.nordstorm.enable = true;
}
```

## Profile System

Profiles are organized in three layers that compose upward:

### Base Profiles

| Profile | Description |
|---------|-------------|
| `base.minimal` | Shell only |
| `base.developer` | Shell + Neovim + Git + Claude Code + MCP servers + Rust tools |
| `base.server` | Shell + Neovim + Git + Kubernetes + security tools (no desktop) |
| `base.desktop` | Developer + desktop components + multimedia/communication/productivity packages |

### Compositor Variants

| Variant | Description |
|---------|-------------|
| `variants.hyprland` | Hyprland compositor configuration |
| `variants.sway` | Sway compositor configuration |
| `variants.niri` | Niri scrollable compositor |
| `variants.cosmic` | COSMIC desktop environment |

### Presets (Base + Variant combinations)

| Preset | Composition |
|--------|-------------|
| `frost-preset` | Developer + Kitty + Kubernetes + OpenCode |
| `blizzard-preset` | Desktop + compositor variant |
| `winter-preset` | Developer + desktop subset |
| `nordstorm-preset` | Full desktop preset |
| `hypr-nord-preset` | Desktop + Hyprland variant |
| `niri-nord-preset` | Desktop + Niri variant |
| `cosmic-nord-preset` | Desktop + Cosmic variant |
| `enhanced-preset` | Extended developer preset |

Legacy profile names (e.g., `blackmatter.profiles.frost.enable`) are backward-compatible aliases that forward to the corresponding preset.

### Darwin Profiles

The macOS profile (`blackmatter.profiles.macos`) contains sub-modules:

| Sub-module | Description |
|------------|-------------|
| `system` | macOS system defaults and preferences |
| `nix` | Nix daemon configuration and GC settings |
| `dns` | Local DNS resolution (uses network topology) |
| `kubectl` | kubectl context and alias configuration |
| `packages` | macOS-specific packages |
| `vms` | Virtual machine tooling |
| `vfkit` | Lightweight macOS virtualization |
| `limits` | File descriptor and process limits (enabled by default) |
| `maintenance` | Periodic maintenance tasks |
| `chrome` | Chrome browser configuration |

## Inline Components

Small modules that live directly in this repo (not extracted):

| Component | Path | Description |
|-----------|------|-------------|
| `gitconfig` | `components/gitconfig/` | Git configuration (aliases, diff tools, merge strategy) |
| `ssh` | `components/ssh/` | SSH client configuration |
| `ssh-aliases` | `components/ssh-aliases/` | SSH host aliases |
| `env` | `components/env/` | Environment variable management |
| `packages` | `components/packages/` | Package groups (rust-renaissance, multimedia, communication, productivity, security, specialized) |
| `attic-netrc` | `components/attic-netrc/` | Attic binary cache authentication |
| `hammerspoon` | `components/hammerspoon/` | macOS Hammerspoon automation |

## Overlays

The `overlays.combined` output folds all overlays into a single overlay function:

**External overlays:**
- `sops-nix` -- SOPS secret management
- `claude-code` -- Claude Code CLI
- `blackmatter-ghostty` -- Ghostty terminal
- `zoekt-mcp` -- Zoekt trigram search (built with fenix Rust toolchain)
- `codesearch` -- Semantic code search (built with fenix Rust toolchain)

**Category overlays:**
- `development` -- Development tools and language servers
- `productivity` -- Productivity applications
- `security` -- Security and penetration testing tools
- `system` -- System utilities

**Fix overlays:**
- `fix-buildenv` -- Critical buildEnv pathsToLinkJSON fix (must be first)
- `gcc15-compat` / `gcc14-compat` -- GCC compatibility shims
- `python312-pin` -- Pin Python 3.12 for packages incompatible with 3.13
- `poetry-fix`, `term-image-fix`, `ghostty-fix`, `aws-c-common-fix`, `buf-fix` -- Package-specific build fixes
- `zls-binary` -- Pre-built ZLS binary (nixpkgs build fails in sandbox)

## Plugin Helper Library

The `lib.pluginHelper` export provides utilities for Neovim plugin management:

```nix
# Usage in a plugin module
{ lib, pkgs, ... }:
let
  pluginHelper = import "${blackmatter}/lib/plugin-helper.nix" { inherit lib pkgs; };
in {
  imports = [
    (pluginHelper.mkPlugin {
      author = "nvim-lua";
      name = "plenary.nvim";
      ref = "master";
      rev = "abc123...";
      hash = "sha256-...";          # Optional: SRI hash for fetchFromGitHub
      configDir = ./config;          # Optional: Lua config directory
      pluginOverride = pkgs: pkgs.vimPlugins.plenary-nvim;  # Optional: use nixpkgs
      packages = pkgs: [ pkgs.nodejs ];  # Optional: system dependencies
      lazy = {                       # Optional: lazy.nvim deferred loading
        enable = true;
        event = [ "VeryLazy" ];
        cmd = [ "Telescope" ];
        keys = [{ key = "<leader>ff"; cmd = "..."; desc = "Find files"; }];
        ft = [ "lua" ];
      };
    })
  ];
}
```

Key functions:
- `mkPlugin` -- Converts a plugin declaration to a full Home Manager module with enable option, file installation, and lazy.nvim spec
- `mkLazyPluginsLua` -- Generates the complete `lazy-plugins.lua` file from all plugin declarations
- `toLuaValue` -- Converts Nix values to Lua syntax (strings, bools, ints, lists, attrsets)

## Network Topology

The shared network topology module (`modules/shared/network-topology/`) defines a schema for infrastructure nodes and services. It is imported by both Darwin and NixOS modules.

```nix
# Set in consumer repo (e.g., nix)
blackmatter.networkTopology = {
  nodes.myserver = {
    ipv4 = "10.0.0.1";
    domains = [ "myserver.local" ];
    k8sApiPort = 6443;
  };
  services.registry = {
    ipv4 = "10.0.0.1";
    domains = [ "registry.local" ];
    port = 5000;
  };
};

# Computed helpers (read-only):
# - dnsAddresses: { "myserver.local" = "10.0.0.1"; }
# - dnsmasqMappings: [{ domain = "/myserver.local"; address = "10.0.0.1"; }]
# - hostsEntries: { "10.0.0.1" = [ "myserver.local" "registry.local" ]; }
```

## Project Structure

```
blackmatter/
├── flake.nix                          # Flake: inputs, module/overlay outputs
├── lib/
│   └── plugin-helper.nix              # Neovim plugin module generator + lazy.nvim
├── overlays/
│   ├── categories/                    # development, productivity, security, system
│   ├── lib/                           # Overlay utilities
│   ├── codesearch.nix                 # Fenix-based codesearch overlay
│   ├── zoekt-mcp.nix                  # Fenix-based zoekt-mcp overlay
│   ├── fix-buildenv.nix              # Critical buildEnv fix
│   ├── gcc15-compat.nix              # GCC 15 compatibility
│   └── ...                            # Other fix overlays
├── modules/
│   ├── shared/
│   │   ├── network-topology/          # Node/service/DNS schema
│   │   ├── nix-binary.nix            # Nix binary cache config
│   │   └── nix-performance.nix       # Nix build performance tuning
│   ├── home-manager/blackmatter/
│   │   ├── profiles/
│   │   │   ├── base/                  # minimal, developer, server, desktop
│   │   │   ├── variants/             # hyprland, sway, niri, cosmic
│   │   │   ├── presets/              # frost, blizzard, winter, nordstorm, etc.
│   │   │   └── {frost,winter,...}/   # Backward-compat aliases
│   │   ├── components/
│   │   │   ├── gitconfig/            # Git configuration
│   │   │   ├── ssh/                  # SSH client config
│   │   │   ├── env/                  # Environment variables
│   │   │   ├── packages/            # Package groups (6 categories)
│   │   │   ├── hammerspoon/         # macOS automation
│   │   │   └── attic-netrc/         # Binary cache auth
│   │   └── themes/                   # Nord + Stylix base16
│   ├── darwin/blackmatter/
│   │   └── profiles/macos/           # 10 macOS sub-modules
│   ├── nixos/blackmatter/
│   │   ├── profiles/                 # NixOS desktop profiles
│   │   └── components/              # 22 NixOS system components
│   └── profiles/
│       └── security-researcher.nix   # Cross-platform security profile
```

## Related Projects

| Repository | Description |
|------------|-------------|
| [blackmatter-shell](https://github.com/pleme-io/blackmatter-shell) | Standalone zsh distribution with 35 bundled tools |
| [blackmatter-nvim](https://github.com/pleme-io/blackmatter-nvim) | Neovim distribution with 56 plugins via lazy.nvim |
| [blackmatter-desktop](https://github.com/pleme-io/blackmatter-desktop) | Desktop environment modules (compositors, terminals, browsers) |
| [blackmatter-claude](https://github.com/pleme-io/blackmatter-claude) | Claude Code MCP server configuration and skills |
| [blackmatter-pleme](https://github.com/pleme-io/blackmatter-pleme) | Pleme-io org conventions and substrate builder skills |
| [blackmatter-security](https://github.com/pleme-io/blackmatter-security) | Penetration testing and security research toolkit |
| [blackmatter-kubernetes](https://github.com/pleme-io/blackmatter-kubernetes) | Kubernetes tooling (kubectl, helm, k3s, flux) |
| [blackmatter-ghostty](https://github.com/pleme-io/blackmatter-ghostty) | Ghostty terminal (macOS source build) |
| [blackmatter-services](https://github.com/pleme-io/blackmatter-services) | System service modules |
| [blackmatter-karakuri](https://github.com/pleme-io/blackmatter-karakuri) | Karakuri window manager integration |
| [blackmatter-macos](https://github.com/pleme-io/blackmatter-macos) | macOS-specific Home Manager modules |
| [blackmatter-tailscale](https://github.com/pleme-io/blackmatter-tailscale) | Tailscale VPN integration (Darwin + NixOS) |
| [blackmatter-tend](https://github.com/pleme-io/blackmatter-tend) | Workspace repository manager integration |
| [blackmatter-opencode](https://github.com/pleme-io/blackmatter-opencode) | OpenCode AI coding agent integration |
| [substrate](https://github.com/pleme-io/substrate) | Reusable Nix build patterns consumed by all repos |

## License

MIT
