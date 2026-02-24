# modules/darwin/blackmatter/profiles/macos/dns/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.dns;
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          dns = {
            enable = mkEnableOption "enable DNS configuration with dnsmasq";

            bind = mkOption {
              type = types.str;
              default = "127.0.0.1";
              description = "IP address to bind dnsmasq to";
            };

            port = mkOption {
              type = types.int;
              default = 53;
              description = "Port for dnsmasq to listen on";
            };

            cacheSize = mkOption {
              type = types.int;
              default = 1000;
              description = "DNS cache size";
            };

            upstreamServers = mkOption {
              type = types.listOf types.str;
              default = ["1.1.1.1" "8.8.8.8"];
              description = "Upstream DNS servers";
            };

            useNetworkTopology = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Use the centralized network topology for DNS mappings.
                When enabled, all nodes and services from blackmatter.networkTopology
                will be automatically configured in dnsmasq.
                Additional mappings can still be added via addresses option.
              '';
            };

            addresses = mkOption {
              type = types.attrsOf types.str;
              default = {};
              description = ''
                Additional DNS address mappings (domain -> IP).
                These will be merged with network topology mappings if useNetworkTopology is true.
              '';
              example = {
                "app.test" = "127.0.0.1";
                "myhost.local" = "192.168.1.100";
              };
            };

            localDomains = mkOption {
              type = types.listOf types.str;
              default = ["local" "test"];
              description = "Domains that should never be forwarded upstream";
            };

            resolverDomains = mkOption {
              type = types.listOf types.str;
              default = ["local" "test"];
              description = "Domains to create macOS resolver entries for";
            };

            enableAliases = mkOption {
              type = types.bool;
              default = true;
              description = "Enable DNS management shell aliases";
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable dnsmasq for local DNS resolution
    services.dnsmasq = {
      enable = true;
      bind = cfg.bind;
      port = cfg.port;
      # Merge network topology addresses with custom addresses
      addresses = mkMerge [
        (mkIf cfg.useNetworkTopology config.blackmatter.networkTopology.dnsAddresses)
        cfg.addresses
      ];
    };

    # Create a custom dnsmasq configuration file and resolver entries
    environment.etc = mkMerge ([
      {
        "dnsmasq.d/local.conf" = {
          text = ''
            # Cache settings
            cache-size=${toString cfg.cacheSize}

            ${concatMapStrings (domain: ''
              # Never forward ${domain} queries upstream
              local=/${domain}/

            '') cfg.localDomains}
            # Upstream DNS servers
            ${concatMapStrings (server: "server=${server}\n") cfg.upstreamServers}
          '';
        };
      }
    ] ++ (map (domain: {
      "resolver/${domain}".text = ''
        nameserver ${cfg.bind}
        port ${toString cfg.port}
      '';
    }) cfg.resolverDomains));

    # Add DNS testing utilities
    environment.systemPackages = with pkgs; [
      dnsutils  # This package includes dig, host, and nslookup
    ];

    # Add helpful aliases
    programs.zsh.interactiveShellInit = mkIf (config.programs.zsh.enable && cfg.enableAliases) ''
      # DNS management aliases
      alias dns-status='sudo launchctl list | grep dnsmasq || echo "dnsmasq not running"'
      alias dns-restart='sudo launchctl kickstart -k system/org.nixos.dnsmasq'
      alias dns-test='dig @127.0.0.1 localhost'
      alias dns-flush='sudo dscacheutil -flushcache'

      # Function to set local DNS
      function set-local-dns() {
        sudo networksetup -setdnsservers Wi-Fi 127.0.0.1
        echo "DNS set to 127.0.0.1 for Wi-Fi"
      }

      # Function to reset DNS to DHCP
      function reset-dns() {
        sudo networksetup -setdnsservers Wi-Fi empty
        echo "DNS reset to DHCP for Wi-Fi"
      }
    '';

    # Add a launchd service to ensure DNS works after network changes
    launchd.daemons.dns-refresh = {
      command = "/usr/bin/dscacheutil -flushcache";
      serviceConfig = {
        StartInterval = 3600; # Run every hour
        RunAtLoad = true;
      };
    };
  };
}
