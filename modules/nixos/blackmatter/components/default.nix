# modules/nixos/blackmatter/components/default.nix
{
  imports = [
    ./wireguard
    ./microservices
    ./goomba
    ./development
    ./productivity
    ./system
    ./multimedia
    ./dnsmasq
    ./nix-builder
    ./nix-maintenance
  ];
}
