# modules/nixos/blackmatter/components/wireguard/site-to-site/default.nix
#
# DEPRECATED: Use services.blackmatter.vpn from blackmatter-vpn instead.
# This module is retained for backward compatibility and will be removed
# in a future release.
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
      description = "Enable site-to-site WireGuard VPNs (DEPRECATED: use services.blackmatter.vpn)";
    };
    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "List of WireGuard interface definitions (DEPRECATED: use services.blackmatter.vpn)";
    };
  };

  config = lib.mkMerge [
    # Hard deprecation assertions — always evaluated when this module is enabled
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(config.services.blackmatter.vpn.enable or false);
          message = ''
            CONFLICT: Cannot use both legacy blackmatter.components.wireguard.site-to-site
            and the new services.blackmatter.vpn module simultaneously.

            Migration steps:
            1. Convert each interface in wireguard.site-to-site.interfaces to a
               services.blackmatter.vpn.links entry
            2. Add presharedKeyFile to every peer (now mandatory)
            3. Set a firewall profile (k8s-control-plane, k8s-full, site-to-site, mesh)
            4. Remove blackmatter.components.wireguard.site-to-site.enable = true
            5. Set services.blackmatter.vpn.enable = true

            See: https://github.com/pleme-io/blackmatter-vpn
          '';
        }
      ];

      warnings = [
        ''
          DEPRECATED: blackmatter.components.wireguard.site-to-site will be REMOVED in the
          next major release. This module has NO security enforcement — no PSK requirement,
          no full-tunnel blocking, no firewall assertions.

          Migrate to services.blackmatter.vpn from blackmatter-vpn:
            1. Convert interfaces to services.blackmatter.vpn.links
            2. Add presharedKeyFile to every peer (post-quantum resistance)
            3. Set a firewall profile or explicit port rules
            4. Remove this module's enable flag

          See: https://github.com/pleme-io/blackmatter-vpn
        ''
      ];
    })

    # Legacy functionality — still works but deprecated
    (lib.mkIf cfg.enable {
      networking.wireguard.interfaces = lib.listToAttrs (lib.map mkIface cfg.interfaces);
      networking.firewall.allowedUDPPorts = lib.mkForce (
        lib.concatLists (lib.map (iface: [iface.listenPort or 51820]) cfg.interfaces)
      );
    })
  ];
}
