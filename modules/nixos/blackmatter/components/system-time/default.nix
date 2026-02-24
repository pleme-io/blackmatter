# modules/nixos/blackmatter/components/system-time/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.systemTime;
in {
  options.blackmatter.components.systemTime = {
    enable = mkEnableOption "system timezone configuration";

    timeZone = mkOption {
      type = types.str;
      default = "America/New_York";
      description = "Timezone for the system";
      example = "America/Fortaleza";
    };
  };

  config = mkIf cfg.enable {
    time.timeZone = cfg.timeZone;
  };
}
