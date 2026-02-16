# modules/nixos/blackmatter/profiles/blizzard/meta/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard;
in {
  config = mkIf cfg.enable {
    system.stateVersion = "24.05";
  };
}
