# Backward compatibility alias for nordstorm → nordstorm-preset
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
          enable = mkEnableOption "enable the nordstorm profile (alias to nordstorm-preset)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the new preset
    blackmatter.profiles.presets.nordstorm-preset.enable = true;
  };
}
