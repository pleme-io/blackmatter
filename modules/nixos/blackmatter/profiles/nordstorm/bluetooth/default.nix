# modules/nixos/blackmatter/profiles/nordstorm/bluetooth/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  config = mkIf cfg.enable {
    services.blueman.enable = true;
  };
}
