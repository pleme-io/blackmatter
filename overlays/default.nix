# Organized overlay system
let
  # Import all category overlays
  categories = {
    development = import ./categories/development.nix;
    productivity = import ./categories/productivity.nix;
    security = import ./categories/security.nix;
    system = import ./categories/system.nix;
  };

  # Generic fix overlays — canonical home for all non-site-specific overlays
  fixes = [
    # Fix buildEnv pathsToLinkJSON bug (CRITICAL - must be first)
    (import ./fix-buildenv.nix)

    # GCC compatibility fixes
    (import ./gcc15-compat.nix)
    (import ./gcc14-compat.nix)

    # Python pin (future-1.0.0 doesn't support 3.13 yet)
    (import ./python312-pin.nix)

    # Package-specific build fixes
    (import ./poetry-fix.nix)
    (import ./term-image-fix.nix)
    (import ./ghostty-fix.nix)
    (import ./aws-c-common-fix.nix)
    (import ./buf-fix.nix)

    # ZLS pre-built binary (nixpkgs build fails with symlink error in sandbox)
    (import ./zls-binary.nix)
  ];
in
  # Combine all overlays
  (builtins.attrValues categories) ++ fixes
