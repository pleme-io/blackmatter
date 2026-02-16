# Backward compatibility alias for frost → frost-preset
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.frost;
in {
  options = {
    blackmatter = {
      profiles = {
        frost = {
          enable = mkEnableOption "enable the frost profile (alias to frost-preset)";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the new preset
    blackmatter.profiles.presets.frost-preset.enable = true;
  };
}
