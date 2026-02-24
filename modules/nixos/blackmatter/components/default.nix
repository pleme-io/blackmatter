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
    ./system-limits
    ./boot-tuning
    ./docker-optimizations
    ./system-time
    ./system-locale
    ./sops-secrets
    ./base-system-tuning
  ];
}
