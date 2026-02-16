# Backward compatibility alias for hypr-nord → hypr-nord-preset
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.hypr-nord;
in {
  options = {
    blackmatter = {
      profiles = {
        hypr-nord = {
          enable = mkEnableOption "enable the hypr-nord profile (alias to hypr-nord-preset)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the new preset
    blackmatter.profiles.presets.hypr-nord-preset.enable = true;
  };
}
