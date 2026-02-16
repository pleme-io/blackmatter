{
  # lib,
  # config,
  ...
}: let
  # cfg = config.blackmatter.profiles;
in {
  imports = [
    # Modular system
    ./base
    ./variants
    ./presets

    # Backward compatibility aliases (can be deleted once migration is complete)
    ./blizzard
    ./winter
    ./frost
    ./nordstorm
    ./niri-nord
    ./cosmic-nord
    ./hypr-nord
  ];
}
