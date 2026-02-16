# modules/nixos/blackmatter/profiles/blizzard/secrets/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.secrets;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.secrets = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable SOPS secrets management";
    };

    ageKeyFile = mkOption {
      type = types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to the age key file for SOPS decryption";
    };
  };

  config = mkIf (profileCfg.enable && cfg.enable) {
    # Configure SOPS with age key
    sops.age.keyFile = cfg.ageKeyFile;
  };
}
