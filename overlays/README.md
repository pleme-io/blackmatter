# Overlay System Documentation

## Overview

This directory contains a comprehensive overlay system for managing package modifications, enhancements, and bundles. Overlays are organized by category for better maintainability.

## Structure

```
overlays/
├── default.nix           # Main entry point combining all overlays
├── lib/
│   └── base.nix         # Overlay utility functions and patterns
├── categories/
│   ├── development.nix  # Development tools and enhancements
│   ├── productivity.nix # Productivity tools and bundles
│   ├── security.nix     # Security tools and hardening
│   └── system.nix       # System administration tools
└── README.md            # This documentation
```

## Categories

### Development (`categories/development.nix`)

Development-focused tools and enhancements:

- **Language Bundles**: `nodejs-dev`, `python-dev`, `rust-dev`, `go-dev`
- **Tool Collections**: `code-formatters`, `language-servers`
- **Enhanced Tools**: `git-enhanced`, `tmux-enhanced`, `neovim-custom`

### Productivity (`categories/productivity.nix`)

Productivity tools and bundles:

- **Shell Tools**: `shell-productivity` (fzf, bat, eza, ripgrep, etc.)
- **Task Management**: `task-tools` (taskwarrior and related)
- **Enhanced Tools**: `fzf-enhanced` with better defaults
- **Media/Docs**: `doc-tools`, `media-productivity`
- **Communication**: `comm-tools` (slack, discord, etc.)

### Security (`categories/security.nix`)

Security tools and hardened configurations:

- **Network Security**: `network-security` (nmap, wireshark, etc.)
- **Cryptography**: `crypto-tools` (gnupg, age, sops, etc.)
- **Password Management**: `password-tools` (bitwarden, keepass, etc.)
- **Enhanced Tools**: `gnupg-enhanced`, `openssh-hardened`
- **Scanning**: `vuln-scanners`, `container-security`

### System (`categories/system.nix`)

System administration and infrastructure:

- **System Admin**: `system-admin` (htop, btop, monitoring tools)
- **Storage**: `disk-tools`, `backup-tools`
- **Containers**: `container-tools` (docker, podman, etc.)
- **Infrastructure**: `iac-tools`, `cloud-cli`, `service-mesh`
- **Enhanced Tools**: `systemd-enhanced` with aliases

## Usage

### Using Bundled Packages

Install any bundle in your configuration:

```nix
environment.systemPackages = with pkgs; [
  # Development bundles
  nodejs-dev
  rust-dev
  
  # Productivity bundles
  shell-productivity
  
  # Security bundles
  crypto-tools
];
```

### Using Enhanced Tools

Enhanced versions have `-enhanced` or `-custom` suffixes:

```nix
environment.systemPackages = with pkgs; [
  git-enhanced      # Git with productivity aliases
  fzf-enhanced      # FZF with better defaults
  gnupg-enhanced    # GnuPG with strong defaults
  openssh-hardened  # SSH with security hardening
];
```

### Creating Custom Overlays

Add new overlays to categories or create new categories:

```nix
# In categories/mycategory.nix
final: prev: {
  my-tool-bundle = prev.buildEnv {
    name = "my-tool-bundle";
    paths = with prev; [
      tool1
      tool2
      tool3
    ];
  };
  
  enhanced-tool = prev.tool.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      # Your enhancements
    '';
  });
}
```

## Advanced Patterns

### Base Library Functions

The `lib/base.nix` provides utility functions for creating overlays:

```nix
# Package overlay
mkPackageOverlay = packages: final: prev: ...

# Modification overlay
mkModificationOverlay = modifications: final: prev: ...

# Version pinning
mkVersionOverlay = versions: final: prev: ...

# Platform-specific
mkPlatformOverlay = { linux ? {}, darwin ? {} }: final: prev: ...

# And many more...
```

### Conditional Packages

Many bundles use conditional inclusion for optional packages:

```nix
paths = with prev; [
  required-package
] ++ prev.lib.optionals (prev ? optional-package) [
  optional-package
];
```

### Platform-Specific Tools

Tools are conditionally included based on platform:

```nix
paths = with prev; [
  cross-platform-tool
] ++ prev.lib.optionals prev.stdenv.isLinux [
  linux-only-tool
] ++ prev.lib.optionals prev.stdenv.isDarwin [
  macos-only-tool
];
```

## Best Practices

1. **Organize by Purpose**: Keep overlays in appropriate categories
2. **Use Bundles**: Create `buildEnv` bundles for related tools
3. **Conditional Inclusion**: Use `optionals` for packages that may not exist
4. **Naming Convention**: 
   - Bundles: `category-purpose` (e.g., `shell-productivity`)
   - Enhanced: `tool-enhanced` or `tool-custom`
5. **Documentation**: Comment complex modifications
6. **Testing**: Test overlays with `nix-build` before system rebuild

## Troubleshooting

### Package Not Found

If a package doesn't exist in nixpkgs:
```nix
] ++ prev.lib.optionals (prev ? package-name) [
  package-name
];
```

### Override Conflicts

If multiple overlays modify the same package, the last one wins. Use `overrideAttrs` carefully.

### Performance

Large `buildEnv` bundles may increase evaluation time. Split very large bundles if needed.

## Adding New Categories

1. Create `categories/newcategory.nix`
2. Add to `default.nix`:
   ```nix
   categories = {
     # existing...
     newcategory = import ./categories/newcategory.nix;
   };
   ```
3. Document in this README

## Contributing

When adding overlays:
1. Choose appropriate category
2. Follow naming conventions
3. Use conditional inclusion for optional packages
4. Test with `./bin/rebuild`
5. Update documentation