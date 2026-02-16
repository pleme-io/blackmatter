# modules/nixos/blackmatter/profiles/blizzard/security/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.security;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  imports = [
    ../../../../../profiles/security-researcher.nix
  ];
  options.blackmatter.profiles.blizzard.security = {
    privacy = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable privacy and anonymity tools (Tor, I2P, VPN, secure messaging).
          Note: May conflict with custom DNS setups (uses dnscrypt-proxy).
        '';
      };

      tor = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Tor network tools when privacy is enabled";
        };

        relay = mkOption {
          type = types.bool;
          default = false;
          description = "Run as Tor relay";
        };

        hiddenServices = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Tor hidden services";
        };

        bridges = mkOption {
          type = types.bool;
          default = false;
          description = "Use Tor bridges for censorship circumvention";
        };
      };

      i2p = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable I2P network tools when privacy is enabled";
        };

        router = mkOption {
          type = types.bool;
          default = false;
          description = "Run I2P router";
        };
      };

      vpn = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable VPN tools when privacy is enabled";
        };

        wireguard = mkOption {
          type = types.bool;
          default = true;
          description = "Include WireGuard tools";
        };

        openvpn = mkOption {
          type = types.bool;
          default = true;
          description = "Include OpenVPN tools";
        };
      };

      messaging = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable secure messaging tools when privacy is enabled";
        };
      };
    };
  };

  config = mkIf profileCfg.enable (mkMerge [
    # Delegate to the privacy module
    (mkIf cfg.privacy.enable {
      security.plo.privacy = {
        enable = true;
        tor = {
          enable = cfg.privacy.tor.enable;
          relay = cfg.privacy.tor.relay;
          hiddenServices = cfg.privacy.tor.hiddenServices;
          bridges = cfg.privacy.tor.bridges;
        };
        i2p = {
          enable = cfg.privacy.i2p.enable;
          router = cfg.privacy.i2p.router;
        };
        vpn = {
          enable = cfg.privacy.vpn.enable;
          wireguard = cfg.privacy.vpn.wireguard;
          openvpn = cfg.privacy.vpn.openvpn;
        };
        messaging = {
          enable = cfg.privacy.messaging.enable;
        };
      };
    })
  ]);
}
