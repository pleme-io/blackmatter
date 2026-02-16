# Base Desktop Profile - Full desktop environment
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.base.desktop;
in {
  options.blackmatter.profiles.base.desktop = {
    enable = mkEnableOption "desktop base profile";
  };

  config = mkIf cfg.enable {
    # Include developer profile
    blackmatter.profiles.base.developer.enable = true;

    # Enable desktop components
    blackmatter.components.desktop.enable = true;

    # Enable all package sets
    blackmatter.components.packages = {
      multimedia.enable = true;
      communication.enable = true;
      productivity.enable = true;
      security.enable = true;
      specialized.enable = true;
    };
  };
}
