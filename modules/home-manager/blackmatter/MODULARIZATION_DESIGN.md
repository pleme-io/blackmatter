# Blackmatter Modularization Design

## Current Architecture Analysis

### Existing Structure
```
blackmatter/
├── components/          # Individual feature modules
│   ├── nvim/           # ✅ Well modularized (plugin system)
│   ├── shell/          # ✅ Well modularized (plugin system)
│   ├── desktop/        # ⚠️  Needs better modularization
│   ├── gitconfig/
│   ├── kubernetes/
│   └── ...
├── profiles/           # User-facing configurations
│   ├── frost/          # Minimal developer profile
│   ├── blizzard/       # Full-featured profile
│   ├── winter/         # Server profile
│   ├── hypr-nord/      # ⚠️  Variant with inline configs
│   ├── niri-nord/      # ⚠️  Variant with inline configs
│   └── cosmic-nord/    # ⚠️  Variant with inline configs
└── lib/                # Helper functions
```

### Issues Identified

1. **Package Duplication**
   - Same packages repeated across profiles (blizzard, hypr-nord, niri-nord)
   - No modular package sets system

2. **Inline Configurations**
   - Waybar, Mako, Fuzzel configs hardcoded in profiles
   - Should be components with Nord theme variant

3. **No Variant System**
   - Desktop environment variants are separate profiles
   - No clean separation of base profile + desktop variant + theme

4. **Missing Theme System**
   - Nord colors hardcoded throughout
   - No centralized theme configuration

5. **Suboptimal Priority Management**
   - Reliance on mkDefault/force
   - No clear precedence system

## Proposed Modularization

### New Architecture

```
blackmatter/
├── components/
│   ├── core/              # NEW: Core functionality
│   │   ├── packages/      # NEW: Modular package sets
│   │   │   ├── multimedia/
│   │   │   ├── communication/
│   │   │   ├── productivity/
│   │   │   ├── development/
│   │   │   ├── security/
│   │   │   └── rust-renaissance/
│   │   └── theming/       # NEW: Theme system
│   │       ├── nord/
│   │       ├── dracula/   # Future
│   │       └── catppuccin/  # Future
│   ├── desktop/
│   │   ├── wayland/       # NEW: Better organization
│   │   │   ├── hyprland/
│   │   │   ├── niri/
│   │   │   ├── cosmic/
│   │   │   └── sway/
│   │   ├── compositors/   # NEW: Wayland compositors
│   │   │   ├── waybar/
│   │   │   ├── mako/
│   │   │   ├── fuzzel/
│   │   │   ├── swaylock/
│   │   │   └── swayidle/
│   │   └── terminals/
│   │       ├── kitty/
│   │       ├── ghostty/
│   │       ├── wezterm/
│   │       └── foot/
│   ├── nvim/              # Already well modularized
│   ├── shell/             # Already well modularized
│   └── ...
├── profiles/
│   ├── base/              # NEW: Base profile definitions
│   │   ├── developer/     # Development-focused
│   │   ├── desktop/       # Full desktop
│   │   ├── server/        # Headless server
│   │   └── minimal/       # Bare minimum
│   ├── variants/          # NEW: Desktop environment variants
│   │   ├── hyprland/
│   │   ├── niri/
│   │   ├── cosmic/
│   │   └── sway/
│   └── presets/           # NEW: Ready-to-use combinations
│       ├── frost/         # Minimal dev (base.developer)
│       ├── blizzard/      # Full desktop (base.desktop + variant.hyprland + theme.nord)
│       ├── winter/        # Server (base.server)
│       ├── hypr-nord/     # Desktop (base.desktop + variant.hyprland + theme.nord)
│       ├── niri-nord/     # Desktop (base.desktop + variant.niri + theme.nord)
│       └── cosmic-nord/   # Desktop (base.desktop + variant.cosmic + theme.nord)
├── lib/
│   ├── package-sets.nix   # NEW: Package set helpers
│   ├── theme-helpers.nix  # NEW: Theme utilities
│   └── variant-helpers.nix  # NEW: Variant composition
└── themes/                # NEW: Centralized themes
    └── nord/
        ├── colors.nix     # Color palette
        ├── gtk.nix        # GTK theming
        ├── qt.nix         # Qt theming
        └── wayland.nix    # Wayland compositor theming
```

### Key Design Principles

1. **Separation of Concerns**
   - Base profiles define **what** you do (dev, desktop, server)
   - Variants define **how** you do it (hyprland, niri, cosmic)
   - Themes define **appearance** (nord, dracula, catppuccin)

2. **Composability**
   ```nix
   # Example: hypr-nord preset
   blackmatter.profiles.presets.hypr-nord = {
     base = "desktop";
     variant = "hyprland";
     theme = "nord";
   };
   ```

3. **No mkDefault/force**
   - Use option priorities explicitly
   - Base profiles: priority 1100 (low)
   - Variants: priority 1000 (default)
   - Themes: priority 900 (high)
   - User overrides: priority 100 (highest)

4. **Package Sets as Components**
   ```nix
   blackmatter.components.packages.multimedia.enable = true;
   blackmatter.components.packages.rust-renaissance.enable = true;
   ```

5. **Inline Configs Become Components**
   ```nix
   # Instead of inline waybar config in profile
   blackmatter.components.desktop.compositors.waybar = {
     enable = true;
     theme = "nord";  # Automatically themed
   };
   ```

## Migration Strategy

### Phase 1: Create New Structure (No Breaking Changes)

1. Create new directories:
   - `components/core/packages/`
   - `components/core/theming/`
   - `components/desktop/wayland/`
   - `components/desktop/compositors/`
   - `profiles/base/`
   - `profiles/variants/`
   - `profiles/presets/`
   - `themes/`

2. Extract package sets from profiles into components

3. Create theme system with Nord theme

4. Create variant modules

5. Create base profile modules

### Phase 2: Migrate Existing Profiles (Backward Compatible)

1. Keep existing profiles as "presets"
2. Make them use new base + variant + theme system internally
3. No API changes - `blackmatter.profiles.frost.enable` still works

### Phase 3: Enhance Components

1. Component-ize waybar, mako, fuzzel, etc.
2. Add theme support to all components
3. Better desktop component organization

## Benefits

1. **Reduced Duplication**
   - Package lists defined once, used many times
   - Configurations defined once, themed automatically

2. **Better Composability**
   - Mix and match base + variant + theme
   - Easy to create new combinations

3. **Clearer Intent**
   - Profiles express purpose, not implementation
   - Easier to understand what a profile does

4. **Easier Maintenance**
   - Update packages in one place
   - Theme changes cascade automatically

5. **No Breaking Changes**
   - Existing profiles work exactly as before
   - New system is opt-in via new presets

6. **Better Control**
   - Explicit priority system
   - No magic mkDefault/force
   - Clear precedence rules

## Implementation Plan

### Step 1: Package Sets
```nix
# components/core/packages/multimedia/default.nix
{ lib, config, pkgs, ... }:
with lib; {
  options.blackmatter.components.packages.multimedia.enable =
    mkEnableOption "multimedia CLI/TUI tools";

  config = mkIf config.blackmatter.components.packages.multimedia.enable {
    home.packages = with pkgs; [
      figlet toilet boxes cowsay fortune lolcat
      yt-dlp mpv ffmpeg sox
      imagemagick feh pandoc
      neofetch cmatrix sl
      cmus aria2 streamlink mediainfo exiftool
      qrencode groff aspell
    ];
  };
}
```

### Step 2: Theme System
```nix
# themes/nord/colors.nix
{
  polar = {
    night0 = "#2E3440";
    night1 = "#3B4252";
    night2 = "#434C5E";
    night3 = "#4C566A";
  };
  snow = {
    storm0 = "#D8DEE9";
    storm1 = "#E5E9F0";
    storm2 = "#ECEFF4";
  };
  frost = {
    frost0 = "#8FBCBB";
    frost1 = "#88C0D0";
    frost2 = "#81A1C1";
    frost3 = "#5E81AC";
  };
  aurora = {
    red = "#BF616A";
    orange = "#D08770";
    yellow = "#EBCB8B";
    green = "#A3BE8C";
    purple = "#B48EAD";
  };
}
```

### Step 3: Variants
```nix
# profiles/variants/hyprland/default.nix
{ lib, config, ... }:
with lib; {
  options.blackmatter.profiles.variants.hyprland.enable =
    mkEnableOption "Hyprland desktop variant";

  config = mkIf config.blackmatter.profiles.variants.hyprland.enable {
    blackmatter.components.desktop.hyprland.enable = true;
    blackmatter.components.desktop.compositors = {
      waybar.enable = true;
      mako.enable = true;
      fuzzel.enable = true;
      swaylock.enable = true;
      swayidle.enable = true;
    };
  };
}
```

### Step 4: Presets (Backward Compatible)
```nix
# profiles/presets/hypr-nord/default.nix
{ lib, config, ... }:
with lib; {
  options.blackmatter.profiles.presets.hypr-nord.enable =
    mkEnableOption "Hyprland with Nord theme preset";

  config = mkIf config.blackmatter.profiles.presets.hypr-nord.enable {
    # Use new modular system
    blackmatter.profiles.base.desktop.enable = true;
    blackmatter.profiles.variants.hyprland.enable = true;
    blackmatter.themes.nord.enable = true;

    # Enable package sets
    blackmatter.components.packages = {
      multimedia.enable = true;
      communication.enable = true;
      productivity.enable = true;
      rust-renaissance.enable = true;
      security.enable = true;
    };
  };
}

# Also keep old path for backward compatibility
blackmatter.profiles.hypr-nord = blackmatter.profiles.presets.hypr-nord;
```

## Testing Strategy

1. **Verification**: Build existing profiles and compare outputs
2. **Bit-for-bit**: Ensure generated configs are identical
3. **Gradual Migration**: Test each component individually
4. **Rollback**: Keep old profiles until new system proven

## Timeline

- **Week 1**: Create structure, package sets, theme system
- **Week 2**: Create variants and base profiles
- **Week 3**: Migrate existing profiles to presets
- **Week 4**: Component-ize inline configs
- **Week 5**: Testing and refinement

## Success Criteria

- ✅ No breaking changes to existing API
- ✅ All profiles produce identical outputs
- ✅ Package duplication eliminated
- ✅ Inline configs extracted to components
- ✅ Theme system works across all components
- ✅ Variant system allows easy composition
- ✅ No use of mkDefault/force
- ✅ Clear priority system
- ✅ Better documentation

---

This modularization will make blackmatter truly composable, maintainable, and extensible while maintaining complete backward compatibility.
