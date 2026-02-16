# modules/nixos/blackmatter/profiles/blizzard/vpn/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.vpn;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.vpn = {
    siteToSite = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable site-to-site WireGuard VPN";
      };

      interfaces = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "WireGuard interface configurations";
        example = literalExpression ''
          [
            {
              name = "wg-s2s";
              privateKeyFile = "/etc/wireguard/privatekey";
              listenPort = 51820;
              addresses = ["192.168.52.3/24"];
              peers = [
                {
                  publicKey = "...";
                  allowedIPs = ["192.168.52.0/24"];
                  endpoint = "192.168.50.2:51820";
                  persistentKeepalive = 10;
                }
              ];
            }
          ]
        '';
      };

      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "VPN interfaces to trust (bypass firewall)";
        example = ["wg-s2s"];
      };

      allowPing = mkOption {
        type = types.bool;
        default = true;
        description = "Allow ICMP ping through VPN";
      };
    };
  };

  config = mkIf (profileCfg.enable && cfg.siteToSite.enable) {
    # Delegate to wireguard component
    blackmatter.components.wireguard.site-to-site = {
      enable = true;
      interfaces = cfg.siteToSite.interfaces;
    };

    # Firewall configuration for VPN
    networking.firewall = {
      allowPing = cfg.siteToSite.allowPing;
      trustedInterfaces = cfg.siteToSite.trustedInterfaces;
    };
  };
}
