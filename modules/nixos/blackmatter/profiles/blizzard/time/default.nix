# modules/nixos/blackmatter/profiles/blizzard/time/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard;
in {
  options = {
    blackmatter = {
      profiles = {
        blizzard = {
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
