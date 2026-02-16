# Winter Preset - Server profile using new modular system
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.winter-preset;
in {
  options.blackmatter.profiles.presets.winter-preset = {
    enable = mkEnableOption "Winter preset (server/headless profile)";
  };

  config = mkIf cfg.enable {
    # Use base server profile
    blackmatter.profiles.base.server.enable = true;
  };
}
