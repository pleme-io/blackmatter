# modules/nixos/blackmatter/profiles/default.nix
{
  # lib,
  # config,
  ...
}: let
  # cfg = config.blackmatter.profiles;
in {
  imports = [
    ./blizzard
    ./nordstorm
    ./niri-nord
    # ./cosmic-nord  # COSMIC not available in nixos-24.11
    ./hypr-nord
  ];
}
