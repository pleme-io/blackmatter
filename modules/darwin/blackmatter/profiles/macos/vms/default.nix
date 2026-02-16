# modules/darwin/blackmatter/profiles/macos/vms/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.vms;
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          vms = {
            enable = mkEnableOption "enable VM configuration for Darwin";

            trustedUsers = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Additional trusted users for Nix in VM context";
              example = ["ldesiqueira"];
            };

            extraTrustedUsers = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Extra trusted users for Nix in VM context";
              example = ["ldesiqueira"];
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    nix.settings = {
      trusted-users = mkIf (cfg.trustedUsers != []) cfg.trustedUsers;
      extra-trusted-users = mkIf (cfg.extraTrustedUsers != []) cfg.extraTrustedUsers;
    };
  };
}
