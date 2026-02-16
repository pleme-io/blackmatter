# modules/nixos/blackmatter/profiles/nordstorm/displayManager/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  config = mkIf cfg.enable {
    # Display manager configuration is in xserver/default.nix
    # This file is kept for structural consistency with blizzard profile
  };
}
