# modules/nixos/blackmatter/components/wireguard/site-to-site/default.nix
{
  config,
  lib,
  ...
}: let
  cfg = config.blackmatter.components.wireguard.site-to-site;
  mkIface = iface: {
    name = iface.name;
    value = {
      ips = iface.addresses; # ← map addresses to ips
      privateKeyFile = iface.privateKeyFile;
      listenPort = iface.listenPort or 51820;
      peers = iface.peers;
    };
  };
in {
  options.blackmatter.components.wireguard.site-to-site = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable site-to-site WireGuard VPNs";
    };
    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "List of WireGuard interface definitions";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.wireguard.interfaces = lib.listToAttrs (lib.map mkIface cfg.interfaces);
    networking.firewall.allowedUDPPorts = lib.mkForce (
      lib.concatLists (lib.map (iface: [iface.listenPort or 51820]) cfg.interfaces)
    );
  };
}
