# Ghostty Terminal Component

Modular configuration for the Ghostty terminal emulator - a fast, GPU-accelerated terminal with Nord theme support.

## Features

- **Nord Theme**: Arctic-themed color palette matching shell (starship) and nvim
- **Performance**: GPU-accelerated rendering with vsync
- **Shell Integration**: Automatic integration with zsh/bash for enhanced features
- **Customizable**: Extensive options for fonts, appearance, behavior

## Basic Usage

Enable ghostty with default Nord theme:

```nix
blackmatter.components.ghostty.enable = true;
```

## Configuration Options

### Font Customization

```nix
blackmatter.components.ghostty = {
  enable = true;
  font = {
    family = "FiraCode Nerd Font";  # Default: "JetBrains Mono"
    size = 12;                      # Default: 11
    thicken = true;                 # Better readability
  };
};
```

### Window Appearance

```nix
blackmatter.components.ghostty = {
  enable = true;
  window = {
    paddingX = 16;        # Horizontal padding (default: 12)
    paddingY = 16;        # Vertical padding (default: 12)
    decoration = true;    # Window borders/titlebar
    gtkTitlebar = true;   # Use GTK titlebar (Linux)
  };
  appearance = {
    backgroundOpacity = 0.95;      # Transparency (0.0-1.0)
    backgroundBlurRadius = 30;     # Blur behind terminal
    unfocusedSplitOpacity = 0.7;   # Dimmed inactive splits
  };
};
```

### Theme Customization

Use Nord theme (default):
```nix
blackmatter.components.ghostty.theme.nordTheme = true;
```

Override specific colors:
```nix
blackmatter.components.ghostty.theme = {
  nordTheme = true;
  customColors = {
    background = "#1e1e1e";
    foreground = "#d4d4d4";
    cursor-color = "#00ff00";
  };
};
```

### Cursor Settings

```nix
blackmatter.components.ghostty.cursor = {
  style = "block";  # "block", "bar", or "underline"
  blink = true;
};
```

### Behavior

```nix
blackmatter.components.ghostty.behavior = {
  confirmClose = false;           # Don't confirm on close
  copyOnSelect = true;            # Auto-copy selection
  mouseHideWhileTyping = true;    # Hide cursor when typing
  scrollbackLimit = 50000;        # Lines in history
  gtkSingleInstance = true;       # One process for all windows
};
```

### Shell Integration

```nix
blackmatter.components.ghostty.shellIntegration = {
  enable = true;
  features = ["cursor" "sudo" "title"];
};
```

Available features:
- `cursor`: Better cursor positioning
- `sudo`: Preserve prompt after sudo
- `title`: Dynamic window titles

### Performance

```nix
blackmatter.components.ghostty.performance = {
  vsync = true;           # Smooth rendering
  minimumContrast = 1.2;  # Text contrast ratio
};
```

### Extra Settings

For settings not covered by options:

```nix
blackmatter.components.ghostty.extraSettings = {
  "macos-option-as-alt" = true;
  "keybind" = "super+t=new_tab";
};
```

## Nord Color Palette

The Nord theme uses these Arctic-inspired colors:

- **Background**: `#2e3440` (Nord Polar Night)
- **Foreground**: `#d8dee9` (Nord Snow Storm)
- **Cursor**: `#88c0d0` (Nord Frost - Cyan)
- **Selection**: `#434c5e` background, `#eceff4` foreground
- **Palette**: Full 16-color Nord spectrum

## Integration with Other Components

Ghostty works seamlessly with:

- **Shell Component**: Inherits zsh/starship configuration
- **Nord Theme**: Matches nvim and shell colors
- **Git Config**: delta diff viewer uses matching Nord colors

## Examples

### Minimal Configuration

```nix
blackmatter.components.ghostty.enable = true;
```

This gives you:
- JetBrains Mono font at size 11
- Nord color theme
- 92% opacity with blur
- Shell integration enabled
- Optimized performance settings

### High-Contrast Setup

```nix
blackmatter.components.ghostty = {
  enable = true;
  appearance.backgroundOpacity = 1.0;  # No transparency
  performance.minimumContrast = 1.5;   # Higher contrast
  theme.nordTheme = true;
};
```

### macOS-Optimized

```nix
blackmatter.components.ghostty = {
  enable = true;
  extraSettings = {
    "macos-option-as-alt" = true;
    "macos-titlebar-style" = "native";
  };
};
```

## Troubleshooting

### Ghostty not starting
Check that ghostty package is available:
```bash
nix-shell -p ghostty --run "ghostty --version"
```

### Colors look wrong
Ensure Nord theme is enabled:
```bash
# Check ghostty config
cat ~/.config/ghostty/config
```

### Performance issues
Try disabling blur:
```nix
blackmatter.components.ghostty.appearance.backgroundBlurRadius = 0;
```

## Related Components

- `blackmatter.components.shell` - Shell configuration (zsh, starship)
- `blackmatter.components.nvim` - Neovim with Nord theme
- `blackmatter.themes.nord` - Nord color palette
