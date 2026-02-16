{ config, lib, pkgs, ... }:

let
  cfg = config.blackmatter.components.nordvpn;
in
{
  options.blackmatter.components.nordvpn = {
    enable = lib.mkEnableOption "NordVPN integration";
    
    method = lib.mkOption {
      type = lib.types.enum [ "native" "openvpn" "gluetun" ];
      default = "gluetun";
      description = "Method to use for NordVPN connection";
    };
    
    credentials = {
      username = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "NordVPN username (will use sops if empty)";
      };
      
      password = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "NordVPN password (will use sops if empty)";
      };
    };
    
    server = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "NordVPN server location";
    };
    
    killSwitch = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable kill switch to block traffic if VPN fails";
    };
  };

  config = lib.mkIf cfg.enable {
    
    # Install required packages
    environment.systemPackages = with pkgs; [
      openvpn
      iptables
      curl
      jq
    ];
    
    # Enable IP forwarding for VPN
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    
    # NordVPN OpenVPN configuration
    services.openvpn.servers = lib.mkIf (cfg.method == "openvpn") {
      nordvpn = {
        config = ''
          client
          dev tun
          proto udp
          remote ${cfg.server}.nordvpn.com 1194
          resolv-retry infinite
          nobind
          persist-key
          persist-tun
          ca /etc/nixos/secrets/nordvpn/ca.crt
          cert /etc/nixos/secrets/nordvpn/client.crt
          key /etc/nixos/secrets/nordvpn/client.key
          remote-cert-tls server
          auth-user-pass /etc/nixos/secrets/nordvpn/auth.txt
          comp-lzo
          verb 3
          cipher AES-256-CBC
          auth SHA256
        '';
        updateResolvConf = true;
        up = "echo 'VPN Connected' | systemd-cat";
        down = "echo 'VPN Disconnected' | systemd-cat";
      };
    };
    
    # Firewall rules for kill switch
    networking.firewall = lib.mkIf cfg.killSwitch {
      extraCommands = ''
        # Allow local traffic
        iptables -I OUTPUT -o lo -j ACCEPT
        iptables -I INPUT -i lo -j ACCEPT
        
        # Allow VPN interface
        iptables -I OUTPUT -o tun+ -j ACCEPT
        iptables -I INPUT -i tun+ -j ACCEPT
        
        # Allow VPN server connection
        iptables -I OUTPUT -p udp --dport 1194 -j ACCEPT
        iptables -I OUTPUT -p tcp --dport 443 -j ACCEPT
        
        # Allow local network
        iptables -I OUTPUT -d 192.168.0.0/16 -j ACCEPT
        iptables -I OUTPUT -d 10.0.0.0/8 -j ACCEPT
        iptables -I OUTPUT -d 172.16.0.0/12 -j ACCEPT
        
        # Block everything else (kill switch)
        iptables -A OUTPUT -j DROP
      '';
      
      extraStopCommands = ''
        # Clean up rules
        iptables -D OUTPUT -o lo -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -i lo -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -o tun+ -j ACCEPT 2>/dev/null || true
        iptables -D INPUT -i tun+ -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -p udp --dport 1194 -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -d 192.168.0.0/16 -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -d 10.0.0.0/8 -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -d 172.16.0.0/12 -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -j DROP 2>/dev/null || true
      '';
    };
    
    # Systemd service for VPN management
    systemd.services.nordvpn-manager = {
      description = "NordVPN Connection Manager";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "nordvpn-start" ''
          set -e
          echo "Starting NordVPN connection..."
          
          # Check VPN status
          if systemctl is-active --quiet openvpn-nordvpn; then
            echo "VPN already running"
            exit 0
          fi
          
          # Start VPN
          systemctl start openvpn-nordvpn
          
          # Wait for connection
          for i in {1..30}; do
            if ip addr show tun0 >/dev/null 2>&1; then
              echo "VPN connected successfully"
              # Test external IP
              EXTERNAL_IP=$(${pkgs.curl}/bin/curl -s https://api.ipify.org)
              echo "External IP: $EXTERNAL_IP"
              exit 0
            fi
            sleep 1
          done
          
          echo "VPN connection failed"
          exit 1
        '';
        
        ExecStop = pkgs.writeShellScript "nordvpn-stop" ''
          echo "Stopping NordVPN connection..."
          systemctl stop openvpn-nordvpn
          echo "VPN disconnected"
        '';
      };
    };
  };
}