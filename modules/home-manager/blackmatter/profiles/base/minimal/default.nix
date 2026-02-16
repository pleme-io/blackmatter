# Minimal Base Profile - Bare essentials only
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.base.minimal;
in {
  options.blackmatter.profiles.base.minimal = {
    enable = mkEnableOption "minimal base profile";
  };

  config = mkIf cfg.enable {
    # Absolute bare minimum - just shell
    blackmatter.components.shell.enable = true;
  };
}
