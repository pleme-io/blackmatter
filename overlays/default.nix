# Organized overlay system
let
  # Import all category overlays
  categories = {
    development = import ./categories/development.nix;
    productivity = import ./categories/productivity.nix;
    security = import ./categories/security.nix;
    system = import ./categories/system.nix;
  };

  # Legacy overlays
  legacy = [
    # Fix buildEnv pathsToLinkJSON bug (CRITICAL - must be first)
    (import ./fix-buildenv.nix)

    # GCC 15 compatibility fixes for packages with strict C issues
    (import ./gcc15-compat.nix)

    # Fix poetry pbs-installer version conflict (2026.1.13 > <2026.0.0)
    (import ./poetry-fix.nix)

    # Fix term-image test failures with Pillow deprecation warnings
    (import ./term-image-fix.nix)

    # Fix ghostty terminfo collision with ncurses
    (import ./ghostty-fix.nix)

    # ZLS pre-built binary (nixpkgs build fails with symlink error in sandbox)
    (import ./zls-binary.nix)

    # codesearch + zoekt-mcp overlays moved to parts/overlays.nix (need fenix input for rustc 1.88+)

    # Custom neovim overlay disabled - lpeg build issues with CMake 4.1
    # Use standard nixpkgs neovim instead
    # (final: prev: {
    #   neovim = prev.callPackage ../pkgs/neovim {
    #     msgpack-c = prev.msgpack-c;
    #   };
    # })
  ];
in
  # Combine all overlays
  (builtins.attrValues categories) ++ legacy
