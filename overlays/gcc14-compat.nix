# GCC 14 Compatibility Fixes
# GCC 14 promotes many pointer type warnings to hard errors, breaking packages
# with older C code. These overrides use GCC 13 stdenv to work around the issues.
final: prev: {
  # NOTE: john and wifite2 are currently disabled in configuration files
  # due to unfixable GCC 14 compilation errors in gpg2john.c
  # See: modules/home-manager/blackmatter/components/packages/security/default.nix
  #      nodes/plo/security-configuration.nix

  # Add packages here as needed when they fail with GCC 14
  # Example:
  # somePackage = prev.somePackage.override {
  #   stdenv = prev.gcc13Stdenv;
  # };
}
