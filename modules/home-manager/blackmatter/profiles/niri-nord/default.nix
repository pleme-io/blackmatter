# Backward compatibility alias for niri-nord → niri-nord-preset
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.niri-nord;
in {
  options = {
    blackmatter = {
      profiles = {
        niri-nord = {
          enable = mkEnableOption "enable the niri-nord profile (alias to niri-nord-preset)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the new preset
    blackmatter.profiles.presets.niri-nord-preset.enable = true;
  };
}
