# Base Server Profile - Headless server environment
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.base.server;
in {
  options.blackmatter.profiles.base.server = {
    enable = mkEnableOption "server base profile";
  };

  config = mkIf cfg.enable {
    # Core components (no desktop)
    blackmatter.components.nvim.enable = true;
    blackmatter.components.shell.enable = true;
    blackmatter.components.gitconfig.enable = true;
    blackmatter.components.kubernetes.enable = true;

    # Essential tools only
    blackmatter.components.packages.rust-renaissance.enable = true;
    blackmatter.components.packages.security.enable = true;
  };
}
