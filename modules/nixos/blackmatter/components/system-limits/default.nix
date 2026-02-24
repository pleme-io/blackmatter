# modules/nixos/blackmatter/components/system-limits/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.systemLimits;
in {
  options.blackmatter.components.systemLimits = {
    enable = mkEnableOption "system PAM login limits (high file/process/memory limits)";
  };

  config = mkIf cfg.enable {
    security.pam.loginLimits = [
      {
        value = "1048576";
        item = "nofile";
        type = "soft";
        domain = "*";
      }
      {
        value = "1048576";
        item = "nofile";
        type = "hard";
        domain = "*";
      }
      {
        value = "65536";
        item = "nproc";
        type = "soft";
        domain = "*";
      }
      {
        value = "65536";
        item = "nproc";
        type = "hard";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "stack";
        type = "soft";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "stack";
        type = "hard";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "memlock";
        type = "soft";
        domain = "*";
      }
      {
        value = "unlimited";
        item = "memlock";
        type = "hard";
        domain = "*";
      }
      {
        value = "unlimited";
        type = "soft";
        domain = "*";
        item = "rss";
      }
      {
        value = "unlimited";
        type = "hard";
        domain = "*";
        item = "rss";
      }
    ];
  };
}
