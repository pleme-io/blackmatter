# modules/darwin/blackmatter/default.nix
{...}: {
  imports = [
    ../../shared/network-topology
    ./profiles/macos
  ];
}
