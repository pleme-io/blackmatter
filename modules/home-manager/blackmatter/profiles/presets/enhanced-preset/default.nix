# Enhanced Preset - Alias to Blizzard preset for backward compatibility
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.enhanced-preset;
in {
  options.blackmatter.profiles.presets.enhanced-preset = {
    enable = mkEnableOption "Enhanced preset (alias to Blizzard preset)";
  };

  config = mkIf cfg.enable {
    # Enhanced is essentially Blizzard - full desktop experience
    blackmatter.profiles.presets.blizzard-preset.enable = true;
  };
}
