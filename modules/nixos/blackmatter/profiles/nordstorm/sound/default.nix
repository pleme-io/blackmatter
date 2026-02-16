# modules/nixos/blackmatter/profiles/nordstorm/sound/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  config = mkIf cfg.enable {
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = false;
      jack.enable = true;
    };
    services.pipewire.wireplumber.enable = true;
  };
}
