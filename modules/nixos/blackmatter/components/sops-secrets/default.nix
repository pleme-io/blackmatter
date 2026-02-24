# modules/nixos/blackmatter/components/sops-secrets/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.sopsSecrets;
in {
  options.blackmatter.components.sopsSecrets = {
    enable = mkEnableOption "SOPS secrets management";

    ageKeyFile = mkOption {
      type = types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to the age key file for SOPS decryption";
    };
  };

  config = mkIf cfg.enable {
    sops.age.keyFile = cfg.ageKeyFile;
  };
}
