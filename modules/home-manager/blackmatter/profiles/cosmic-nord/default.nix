# Backward compatibility alias for cosmic-nord → cosmic-nord-preset
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.cosmic-nord;
in {
  options = {
    blackmatter = {
      profiles = {
        cosmic-nord = {
          enable = mkEnableOption "enable the cosmic-nord profile (alias to cosmic-nord-preset)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the new preset
    blackmatter.profiles.presets.cosmic-nord-preset.enable = true;
  };
}
