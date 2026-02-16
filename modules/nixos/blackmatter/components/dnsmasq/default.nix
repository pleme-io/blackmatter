{ config, lib, pkgs, ... }:

let
  cfg = config.blackmatter.components.dnsmasq;
in
{
  options.blackmatter.components.dnsmasq = {
    enable = lib.mkEnableOption "dnsmasq local DNS resolver";
    
    upstreamDNS = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "1.1.1.1" "8.8.8.8" ];
      description = "Upstream DNS servers";
    };
    
    localDomains = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        "plo.local" = "192.168.50.3";
        "media.local" = "192.168.50.3";
      };
      description = "Local domain mappings";
    };
    
    networkInterface = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "192.168.50.3";
      description = "Network interface to bind to (127.0.0.1 for localhost only)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Disable systemd-resolved to avoid conflicts
    services.resolved.enable = false;
    
    # Enable dnsmasq
    services.dnsmasq = {
      enable = true;
      
      # Bind to specified interface
      settings = {
        # Listen on configured interface
        listen-address = "${cfg.networkInterface},::1";
        bind-interfaces = true;
        
        # Don't read /etc/resolv.conf
        no-resolv = true;
        
        # Upstream DNS servers
        server = cfg.upstreamDNS;
        
        # Cache settings
        cache-size = 1000;
        
        # Don't forward private ranges
        bogus-priv = true;
        
        # Don't forward non-routed addresses
        no-negcache = true;
        
        # Additional options for k3s compatibility
        # This prevents loops when CoreDNS queries local DNS
        local-service = true;
        
        # Local domain mappings
        address = lib.mapAttrsToList (domain: ip: "/${domain}/${ip}") cfg.localDomains;
        
        # Log DNS queries (useful for debugging)
        # log-queries = true;
        # log-facility = "/var/log/dnsmasq.log";
      };
    };
    
    
    # Configure system to use dnsmasq
    networking = {
      nameservers = [ "127.0.0.1" ];
      
      # Ensure resolv.conf is managed by NixOS
      resolvconf.enable = true;
      resolvconf.extraConfig = ''
        # Fallback nameservers if dnsmasq fails
        name_servers="127.0.0.1 1.1.1.1 8.8.8.8"
      '';
      
      # Open firewall for DNS if listening on network interface
      firewall.allowedUDPPorts = lib.mkIf (cfg.networkInterface != "127.0.0.1") [ 53 ];
      firewall.allowedTCPPorts = lib.mkIf (cfg.networkInterface != "127.0.0.1") [ 53 ];
    };
  };
}