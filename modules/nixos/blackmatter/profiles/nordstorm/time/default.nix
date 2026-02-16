# modules/nixos/blackmatter/profiles/nordstorm/time/default.nix
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
          timeZone = mkOption {
            type = types.str;
            default = "America/New_York";
            description = "Timezone for the system";
            example = "America/Fortaleza";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    time.timeZone = cfg.timeZone;
  };
}
