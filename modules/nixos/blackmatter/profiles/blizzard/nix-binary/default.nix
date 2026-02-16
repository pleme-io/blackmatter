# modules/nixos/blackmatter/profiles/blizzard/nix-binary/default.nix
# Nix binary version management - NixOS wrapper for shared module
{
  config,
  lib,
  inputs ? null,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.nixBinary;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  # Import the shared cross-platform nix-binary module
  imports = [
    ../../../../../shared/nix-binary.nix
  ];

  options.blackmatter.profiles.blizzard.nixBinary = {
    variant = mkOption {
      type = types.enum ["nixpkgs-stable" "nixpkgs-latest" "nixpkgs-git"];
      default = "nixpkgs-stable";
      description = ''
        Which Nix binary variant to use. See nix.binary.variant for details.
        This is a convenience wrapper for the shared nix.binary module.
      '';
    };
  };

  config = mkIf profileCfg.enable {
    # Delegate to shared nix.binary module
    nix.binary.variant = cfg.variant;
  };
}
