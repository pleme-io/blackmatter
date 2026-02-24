# Split-horizon DNS module
# Provides internal/external DNS resolution with Kubernetes integration
# Uses dnsmasq for local DNS + CoreDNS for K8s service discovery + Cloudflare DDNS
{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.blackmatter.components.dnsSplitHorizon;

  # CoreDNS configuration for Kubernetes services
  corednsConfig = ''
    # Internal Kubernetes services
    ${cfg.k8sDomain}:53 {
      errors
      health {
        lameduck 5s
      }
      ready
      kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
        ttl 30
      }
      prometheus :9153
      forward . ${cfg.upstreamDns}
      cache 30
      loop
      reload
      loadbalance
    }

    # External domain handling (when inside network)
    ${cfg.externalDomain}:53 {
      errors
      health
      # Rewrite external domain to internal
      rewrite name substring ${cfg.externalDomain} ${cfg.internalDomain} answer auto
      forward . 127.0.0.1:5353
      cache 30
      reload
    }
  '';

  # Dynamic DNS update script
  ddnsUpdateScript = pkgs.writeScriptBin "ddns-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    # Get current public IP
    CURRENT_IP=$(${pkgs.curl}/bin/curl -s https://api.ipify.org)

    # Read last known IP
    LAST_IP_FILE="/var/lib/ddns/last-ip"
    mkdir -p $(dirname $LAST_IP_FILE)
    LAST_IP=$(cat $LAST_IP_FILE 2>/dev/null || echo "")

    if [ "$CURRENT_IP" != "$LAST_IP" ]; then
      echo "IP changed from $LAST_IP to $CURRENT_IP"

      # Update Cloudflare
      ${pkgs.curl}/bin/curl -X PUT \
        "https://api.cloudflare.com/client/v4/zones/${cfg.cloudflare.zoneId}/dns_records/${cfg.cloudflare.recordId}" \
        -H "Authorization: Bearer ${cfg.cloudflare.apiToken}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${cfg.ddnsHostname}\",\"content\":\"$CURRENT_IP\",\"ttl\":120,\"proxied\":false}"

      echo "$CURRENT_IP" > $LAST_IP_FILE
    fi
  '';

in {
  options.blackmatter.components.dnsSplitHorizon = {
    enable = mkEnableOption "split-horizon DNS for internal/external access";

    internalDomain = mkOption {
      type = types.str;
      default = "local";
      description = "Internal domain for home network";
    };

    k8sDomain = mkOption {
      type = types.str;
      default = "k8s.${cfg.internalDomain}";
      description = "Domain for Kubernetes service discovery via CoreDNS";
    };

    externalDomain = mkOption {
      type = types.str;
      example = "example.io";
      description = "External domain for internet access";
    };

    upstreamDns = mkOption {
      type = types.str;
      default = "1.1.1.1 8.8.8.8";
      description = "Upstream DNS servers";
    };

    interfaces = mkOption {
      type = types.str;
      default = "lo";
      description = "Network interfaces for dnsmasq to bind to (comma-separated)";
    };

    ddnsHostname = mkOption {
      type = types.str;
      default = "home";
      description = "Hostname for dynamic DNS updates";
    };

    cloudflare = {
      apiToken = mkOption {
        type = types.str;
        description = "Cloudflare API token";
      };

      zoneId = mkOption {
        type = types.str;
        description = "Cloudflare zone ID";
      };

      recordId = mkOption {
        type = types.str;
        description = "Cloudflare DNS record ID";
      };
    };

    kubernetesIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Kubernetes service discovery via CoreDNS";
    };
  };

  config = mkIf cfg.enable {
    # Enhance existing dnsmasq configuration
    services.dnsmasq = {
      enable = true;
      settings = {
        interface = mkDefault cfg.interfaces;
        bind-interfaces = true;

        # Domain configuration
        domain = cfg.internalDomain;
        local = "/${cfg.internalDomain}/";
        expand-hosts = true;

        # Forward external domain queries to CoreDNS
        server = [
          "/${cfg.externalDomain}/127.0.0.1#5354"
          "/${cfg.k8sDomain}/127.0.0.1#5353"
        ];

        # Cache settings
        cache-size = 1000;

        # Security
        domain-needed = true;
        bogus-priv = true;
        stop-dns-rebind = true;
        rebind-localhost-ok = true;

        # DNSSEC
        dnssec = true;
        trust-anchor = ".,19036,8,2,49AAC11D7B6F6446702E54A1607371607A1A41855200FD2CE1CDDE32F24E8FB5";
      };
    };

    # CoreDNS for Kubernetes integration
    systemd.services.coredns = mkIf cfg.kubernetesIntegration {
      description = "CoreDNS for Kubernetes service discovery";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.coredns}/bin/coredns -conf=/etc/coredns/Corefile";
        Restart = "always";
        RestartSec = "10s";
        User = "coredns";
        Group = "coredns";
        AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        NoNewPrivileges = true;
      };
    };

    # CoreDNS configuration
    environment.etc."coredns/Corefile" = mkIf cfg.kubernetesIntegration {
      text = corednsConfig;
      user = "coredns";
      group = "coredns";
    };

    # Dynamic DNS updater
    systemd.services.ddns-updater = {
      description = "Dynamic DNS updater for external access";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${ddnsUpdateScript}/bin/ddns-update";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    systemd.timers.ddns-updater = {
      description = "Dynamic DNS update timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "5min";
        Unit = "ddns-updater.service";
      };
    };

    # Create coredns user
    users.users.coredns = mkIf cfg.kubernetesIntegration {
      isSystemUser = true;
      group = "coredns";
      description = "CoreDNS service user";
    };

    users.groups.coredns = mkIf cfg.kubernetesIntegration {};

    # Firewall rules
    networking.firewall = {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
