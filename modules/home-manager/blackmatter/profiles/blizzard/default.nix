# Backward compatibility alias for blizzard → blizzard-preset
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
          enable = mkEnableOption "enable the blizzard profile (alias to blizzard-preset)";

          # Keep xserver option for backward compatibility (used by zek node)
          xserver = {
            enable = mkEnableOption "Enable xserver configuration at system level";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the new preset
    blackmatter.profiles.presets.blizzard-preset.enable = true;
  };
}
