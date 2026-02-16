# blackmatter/ - Home-Manager Module Framework

Custom module framework providing extensive user environment configuration options.

## Structure

### components/
Individual features that can be enabled:
- `nvim/` - Comprehensive Neovim configuration with 200+ plugins
- `shell/` - Shell environment (zsh, tmux, starship, tools)
- `desktop/` - Desktop applications and window managers
- `gitconfig/` - Git configuration
- `kubernetes/` - Kubernetes tools and utilities
- `microservices/` - User-level service configurations

### profiles/
Pre-configured component sets:
- `blizzard` - Full-featured desktop environment
- `frost` - Minimal desktop setup
- `winter` - Server/headless configuration

## Usage

```nix
{
  imports = [ ./modules/home-manager/blackmatter ];
  
  # Enable a profile
  blackmatter.profiles.blizzard.enable = true;
  
  # Or enable individual components
  blackmatter.components.nvim.enable = true;
  blackmatter.components.shell.enable = true;
}
```

## Philosophy

- **Modular**: Each component is independent
- **Configurable**: Extensive options for customization
- **Declarative**: Pure Nix expressions
- **Portable**: Works on NixOS, other Linux, and macOS

## Key Features

- Extensive Neovim plugin ecosystem
- Multiple window manager support
- Development environment management
- Consistent theming across applications
- Shell productivity enhancements
