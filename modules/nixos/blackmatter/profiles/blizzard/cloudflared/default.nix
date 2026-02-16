# modules/nixos/blackmatter/profiles/blizzard/cloudflared/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.cloudflared;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.cloudflared = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Cloudflare Tunnel";
    };

    tunnelId = mkOption {
      type = types.str;
      description = "Cloudflare tunnel ID";
    };

    accountId = mkOption {
      type = types.str;
      description = "Cloudflare account ID";
    };

    tunnelSecret = mkOption {
      type = types.str;
      description = "Cloudflare tunnel secret";
    };

    ingress = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostname = mkOption {
            type = types.str;
            description = "Hostname to route (supports wildcards)";
          };
          service = mkOption {
            type = types.str;
            description = "Backend service URL";
          };
        };
      });
      default = [];
      description = "Ingress rules for the tunnel";
      example = literalExpression ''
        [
          {
            hostname = "*.staging.example.com";
            service = "http://192.168.50.100:80";
          }
          {
            hostname = "staging.example.com";
            service = "http://192.168.50.100:80";
          }
        ]
      '';
    };

    catchAllService = mkOption {
      type = types.str;
      default = "http_status:404";
      description = "Catch-all service for unmatched requests";
    };

    helperScripts = mkOption {
      type = types.bool;
      default = true;
      description = "Install cloudflared helper scripts";
    };
  };

  config = mkIf (profileCfg.enable && cfg.enable) (let
    configFile = pkgs.writeText "cloudflared-config.yml" (''
      tunnel: ${cfg.tunnelId}
      credentials-file: /var/lib/cloudflared/credentials.json

      ingress:
    '' + (concatMapStrings (rule: ''
        - hostname: "${rule.hostname}"
          service: ${rule.service}
    '') cfg.ingress) + ''
        - service: ${cfg.catchAllService}
    '');

    credentialsFile = pkgs.writeText "tunnel-credentials.json" (builtins.toJSON {
      AccountTag = cfg.accountId;
      TunnelID = cfg.tunnelId;
      TunnelSecret = cfg.tunnelSecret;
    });
  in {
    environment.systemPackages = with pkgs; [
      cloudflared
    ] ++ optionals cfg.helperScripts [
      (writeScriptBin "cloudflared-status" ''
        #!${bash}/bin/bash
        echo "Cloudflared service status:"
        systemctl status cloudflared --no-pager
        echo ""
        echo "Recent logs:"
        journalctl -u cloudflared -n 50 --no-pager
      '')

      (writeScriptBin "cloudflared-restart" ''
        #!${bash}/bin/bash
        echo "Restarting cloudflared service..."
        sudo systemctl restart cloudflared
        sleep 2
        systemctl status cloudflared --no-pager
      '')

      (writeScriptBin "cloudflared-config" ''
        #!${bash}/bin/bash
        echo "=== Cloudflared Configuration ==="
        echo "Config file: ${configFile}"
        echo ""
        cat ${configFile}
      '')
    ];

    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
      description = "Cloudflare Tunnel daemon user";
    };

    users.groups.cloudflared = {};

    systemd.services.cloudflared = {
      description = "Cloudflare Tunnel";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      preStart = ''
        mkdir -p /var/lib/cloudflared
        cp ${credentialsFile} /var/lib/cloudflared/credentials.json
        chmod 600 /var/lib/cloudflared/credentials.json
        chown cloudflared:cloudflared /var/lib/cloudflared/credentials.json
      '';

      serviceConfig = {
        Type = "simple";
        User = "cloudflared";
        Group = "cloudflared";
        Restart = "on-failure";
        RestartSec = "5s";

        StateDirectory = "cloudflared";
        StateDirectoryMode = "0700";

        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config ${configFile} run";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = "/var/lib/cloudflared";
      };
    };
  });
}
