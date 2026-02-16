# modules/nixos/blackmatter/profiles/nordstorm/locale/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  options = {
    blackmatter = {
      profiles = {
        nordstorm = {
          locale = {
            defaultLocale = mkOption {
              type = types.str;
              default = "en_US.UTF-8";
              description = "Default locale for the system";
            };

            extraLocaleSettings = mkOption {
              type = types.attrsOf types.str;
              default = {};
              description = "Extra locale settings";
              example = {
                LC_ADDRESS = "en_US.UTF-8";
                LC_IDENTIFICATION = "en_US.UTF-8";
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    i18n.defaultLocale = cfg.locale.defaultLocale;
    i18n.extraLocaleSettings = cfg.locale.extraLocaleSettings;
  };
}
