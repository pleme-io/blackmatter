# nix-place — Managed Nix flake placement tool
#
# Provides pkgs.nix-place from the nix-place flake input.
# Used by flake-fragment-helpers activation scripts.
{inputs}:
  final: prev: {
    nix-place = inputs.nix-place.packages.${prev.system}.default;
  }
