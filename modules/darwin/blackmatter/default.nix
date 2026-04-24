# modules/darwin/blackmatter/default.nix
{lib, ...}: {
  imports = [
    ../../shared/network-topology
    ./profiles/macos
    ./components
  ];

  # Tatara-script on /run/current-system/sw/bin by default — every
  # pleme-io darwin workstation gets it via the tatara-lisp darwin
  # module wired into darwinModules.blackmatter. Override with
  #   blackmatter.components.tatara-script.enable = false;
  # on the rare machine where it's unwanted.
  config = {
    blackmatter.components.tatara-script.enable = lib.mkDefault true;
  };
}
