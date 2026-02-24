# modules/shared/nix-binary.nix
# Cross-platform Nix binary version management
# Works on both NixOS and Darwin (macOS)
{
  config,
  lib,
  pkgs,
  inputs ? null,
  ...
}:
with lib; let
  cfg = config.nix.binary;
in {

  options = {
    nix.binary = {
      variant = mkOption {
        type = types.enum ["nixpkgs-stable" "nixpkgs-latest" "nixpkgs-git"];
        default = "nixpkgs-stable";
        description = ''
          Which Nix binary variant to use:
          - nixpkgs-stable: Stable Nix from nixpkgs (default)
          - nixpkgs-latest: Latest Nix from nixpkgs
          - nixpkgs-git: Bleeding edge Nix from git

          Works on both NixOS and Darwin (macOS).
        '';
      };

      package = mkOption {
        type = types.package;
        description = ''
          The Nix package to use. Automatically set based on variant.
          Can be overridden for custom Nix builds.
        '';
      };
    };
  };

  config = {
    # Set package based on variant
    nix.binary.package = mkDefault (
      if cfg.variant == "nixpkgs-stable"
      then pkgs.nixVersions.stable
      else if cfg.variant == "nixpkgs-latest"
      then pkgs.nixVersions.latest
      else if cfg.variant == "nixpkgs-git"
      then pkgs.nixVersions.git
      else pkgs.nixVersions.stable
    );

    # Set nix.package in the system configuration
    nix.package = mkDefault cfg.package;
  };
}
