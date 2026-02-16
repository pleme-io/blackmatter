# modules/nixos/blackmatter/profiles/blizzard/bluetooth/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard;
  btCfg = cfg.bluetooth;
  isWorkstation = cfg.variant == "workstation" || cfg.variant == "workstation-agent";
in {
  options.blackmatter.profiles.blizzard.bluetooth = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Bluetooth (blueman). Only activates on workstation variants.";
    };
  };

  config = mkIf (cfg.enable && btCfg.enable && isWorkstation) {
    services.blueman.enable = true;
  };
}
