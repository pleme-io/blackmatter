# modules/nixos/blackmatter/profiles/blizzard/sound/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard;
  soundCfg = cfg.sound;
  isWorkstation = cfg.variant == "workstation" || cfg.variant == "workstation-agent";
in {
  options.blackmatter.profiles.blizzard.sound = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable PipeWire audio stack. Only activates on workstation variants.";
    };
  };

  config = mkIf (cfg.enable && soundCfg.enable && isWorkstation) {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = false;
      jack.enable = true;
    };
    services.pipewire.wireplumber.enable = true;
  };
}
