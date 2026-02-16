# modules/darwin/blackmatter/profiles/macos/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos;
in {
  imports = [
    ./system
    ./nix
    ./dns
    ./kubectl
    ./packages
    ./vms
    ./vfkit
    ./limits
    ./maintenance
  ];

  options = {
    blackmatter = {
      profiles = {
        macos = {
          enable = mkEnableOption "enable the macOS profile";

          # Convenience option to enable all components at once
          enableAll = mkOption {
            type = types.bool;
            default = false;
            description = "Enable all macOS profile components with defaults";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # When enableAll is true, enable all components
    # enableAll propagates to sub-modules; explicit enable = true in node config
    # takes precedence over mkDefault. Don't self-reference cfg.X.enable here
    # (causes infinite recursion when no explicit definition exists).
    blackmatter.profiles.macos.system.enable = mkDefault cfg.enableAll;
    blackmatter.profiles.macos.nix.enable = mkDefault cfg.enableAll;
    blackmatter.profiles.macos.dns.enable = mkDefault cfg.enableAll;
    blackmatter.profiles.macos.kubectl.enable = mkDefault cfg.enableAll;
    blackmatter.profiles.macos.packages.enable = mkDefault cfg.enableAll;
    blackmatter.profiles.macos.vms.enable = mkDefault cfg.enableAll;
    blackmatter.profiles.macos.vfkit.enable = mkDefault cfg.enableAll;
    # Limits enabled by default - required for Nix builds that open many files
    blackmatter.profiles.macos.limits.enable = mkDefault true;
    blackmatter.profiles.macos.maintenance.enable = mkDefault cfg.enableAll;
  };
}
