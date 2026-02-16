# modules/nixos/blackmatter/default.nix
{
  # lib,
  # config,
  ...
}: let
  # cfg = config.blackmatter;
in {
  imports = [
    ../../shared/network-topology
    ./profiles
    ./components
  ];

  # options = {
  #   blackmatter = {
  #     enable = mkEnableOption "enable blackmatter";
  #   };
  # };
}
