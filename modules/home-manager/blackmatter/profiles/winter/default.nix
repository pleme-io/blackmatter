# Backward compatibility alias for winter → winter-preset
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.winter;
in {
  options = {
    blackmatter = {
      profiles = {
        winter = {
          enable = mkEnableOption "enable the winter profile (alias to winter-preset)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the new preset
    blackmatter.profiles.presets.winter-preset.enable = true;
  };
}
