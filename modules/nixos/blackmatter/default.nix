# modules/nixos/blackmatter/default.nix
{lib, ...}: {
  imports = [
    ../../shared/network-topology
    ./profiles
    ./components
  ];

  # Tatara-script on the system PATH by default — every pleme-io NixOS
  # node gets it via the tatara-lisp NixOS module wired into
  # nixosModules.blackmatter. Override with
  #   blackmatter.components.tatara-script.enable = false;
  # on the rare node where it's unwanted.
  config = {
    blackmatter.components.tatara-script.enable = lib.mkDefault true;
  };
}
