# NixOS performance monitoring module
{ lib, config, pkgs, ... }:
let
  perf = import ../../../../lib/performance.nix { inherit lib pkgs; };
  cfg = config.blackmatter.performance;
in {
  options.blackmatter.performance = with lib; {
    enable = mkEnableOption "Performance monitoring and optimization";
    
    monitoring = {
      enable = mkEnableOption "Enable performance metrics collection";
      
      interval = mkOption {
        type = types.str;
        default = "hourly";
        description = "How often to collect metrics";
      };
      
      retentionDays = mkOption {
        type = types.int;
        default = 30;
        description = "Days to retain metrics";
      };
      
      metricsDir = mkOption {
        type = types.path;
        default = "/var/lib/nix-performance";
        description = "Directory to store metrics";
      };
    };
    
    optimization = {
      enable = mkEnableOption "Enable automatic performance optimizations";
      
      gcAutomatic = mkOption {
        type = types.bool;
        default = true;
        description = "Enable automatic garbage collection";
      };
      
      gcDates = mkOption {
        type = types.str;
        default = "weekly";
        description = "When to run garbage collection";
      };
      
      gcOptions = mkOption {
        type = types.str;
        default = "--delete-older-than 30d";
        description = "Options to pass to nix-collect-garbage";
      };
      
      buildCores = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Number of cores to use for builds (null = auto)";
      };
      
      maxJobs = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Maximum parallel build jobs (null = auto)";
      };
    };
    
    reporting = {
      enable = mkEnableOption "Enable performance reporting";
      
      dashboard = mkOption {
        type = types.bool;
        default = false;
        description = "Enable web dashboard";
      };
      
      dashboardPort = mkOption {
        type = types.port;
        default = 9090;
        description = "Port for performance dashboard";
      };
      
      alerts = {
        enable = mkEnableOption "Enable performance alerts";
        
        thresholds = {
          evalTime = mkOption {
            type = types.int;
            default = 60;
            description = "Alert if evaluation takes longer than N seconds";
          };
          
          buildTime = mkOption {
            type = types.int;
            default = 600;
            description = "Alert if build takes longer than N seconds";
          };
          
          diskUsage = mkOption {
            type = types.int;
            default = 90;
            description = "Alert if /nix/store usage exceeds N percent";
          };
        };
      };
    };
  };
  
  config = mkIf cfg.enable (mkMerge [
    # Base configuration
    {
      environment.systemPackages = with pkgs; [
        # Performance tools
        nix-du
        nix-tree
        nix-diff
        
        # Monitoring tools
        (pkgs.writeScriptBin "nix-perf" (builtins.readFile ../../../../bin/nix-perf))
      ];
      
      # Nix configuration for performance
      nix.settings = mkMerge [
        {
          # Always use binary caches
          substituters = lib.mkDefault [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
          ];
          
          trusted-public-keys = lib.mkDefault [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          
          # Parallel builds
          cores = cfg.optimization.buildCores;
          max-jobs = cfg.optimization.maxJobs;
          
          # Keep build logs
          keep-build-log = true;
          
          # Enable flakes
          experimental-features = [ "nix-command" "flakes" ];
        }
      ];
    }
    
    # Monitoring configuration
    (mkIf cfg.monitoring.enable {
      systemd.services.nix-performance-monitor = {
        description = "Nix Performance Monitor";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeScript "nix-performance-monitor" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail
            
            METRICS_DIR="${cfg.monitoring.metricsDir}"
            mkdir -p "$METRICS_DIR"
            
            # Collect system metrics
            TIMESTAMP=$(date +%s)
            
            # Store size
            STORE_SIZE=$(du -sb /nix/store | cut -f1)
            echo "{\"timestamp\": $TIMESTAMP, \"name\": \"store_size\", \"value\": $STORE_SIZE, \"unit\": \"bytes\"}" >> "$METRICS_DIR/system-$TIMESTAMP.json"
            
            # Store path count
            STORE_PATHS=$(find /nix/store -maxdepth 1 -type d | wc -l)
            echo "{\"timestamp\": $TIMESTAMP, \"name\": \"store_paths\", \"value\": $STORE_PATHS, \"unit\": \"count\"}" >> "$METRICS_DIR/system-$TIMESTAMP.json"
            
            # GC roots
            GC_ROOTS=$(nix-store --gc --print-roots | wc -l)
            echo "{\"timestamp\": $TIMESTAMP, \"name\": \"gc_roots\", \"value\": $GC_ROOTS, \"unit\": \"count\"}" >> "$METRICS_DIR/system-$TIMESTAMP.json"
            
            # Clean old metrics
            find "$METRICS_DIR" -name "*.json" -mtime +${toString cfg.monitoring.retentionDays} -delete
          '';
        };
      };
      
      systemd.timers.nix-performance-monitor = {
        description = "Nix Performance Monitor Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.monitoring.interval;
          Persistent = true;
        };
      };
    })
    
    # Optimization configuration
    (mkIf cfg.optimization.enable {
      # Automatic garbage collection
      nix.gc = mkIf cfg.optimization.gcAutomatic {
        automatic = true;
        dates = cfg.optimization.gcDates;
        options = cfg.optimization.gcOptions;
      };
      
      # Optimize store on activation
      system.activationScripts.nix-optimize = ''
        echo "Optimizing Nix store..."
        ${pkgs.nix}/bin/nix-store --optimise || true
      '';
      
      # Auto-optimize after builds
      nix.settings.auto-optimise-store = true;
    })
    
    # Reporting configuration
    (mkIf cfg.reporting.enable {
      # Performance report generation
      systemd.services.nix-performance-report = {
        description = "Generate Nix Performance Report";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeScriptBin "nix-perf" (builtins.readFile ../../../../bin/nix-perf)}/bin/nix-perf report";
        };
      };
      
      systemd.timers.nix-performance-report = {
        description = "Nix Performance Report Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    })
    
    # Dashboard configuration
    (mkIf (cfg.reporting.enable && cfg.reporting.dashboard) {
      # Simple web dashboard using Python
      systemd.services.nix-performance-dashboard = {
        description = "Nix Performance Dashboard";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        
        serviceConfig = {
          Type = "simple";
          ExecStart = pkgs.writeScript "nix-performance-dashboard" ''
            #!${pkgs.python3}/bin/python3
            import http.server
            import json
            import os
            import glob
            from datetime import datetime
            
            METRICS_DIR = "${cfg.monitoring.metricsDir}"
            PORT = ${toString cfg.reporting.dashboardPort}
            
            class MetricsHandler(http.server.BaseHTTPRequestHandler):
                def do_GET(self):
                    if self.path == "/":
                        self.send_response(200)
                        self.send_header("Content-type", "text/html")
                        self.end_headers()
                        
                        html = """
                        <html>
                        <head><title>Nix Performance Dashboard</title></head>
                        <body>
                        <h1>Nix Performance Dashboard</h1>
                        <h2>Recent Metrics</h2>
                        <pre id="metrics">Loading...</pre>
                        <script>
                        fetch('/metrics')
                          .then(r => r.json())
                          .then(data => {
                            document.getElementById('metrics').textContent = JSON.stringify(data, null, 2);
                          });
                        setInterval(() => location.reload(), 60000);
                        </script>
                        </body>
                        </html>
                        """
                        self.wfile.write(html.encode())
                        
                    elif self.path == "/metrics":
                        self.send_response(200)
                        self.send_header("Content-type", "application/json")
                        self.end_headers()
                        
                        metrics = []
                        for file in glob.glob(f"{METRICS_DIR}/*.json"):
                            try:
                                with open(file) as f:
                                    for line in f:
                                        metrics.append(json.loads(line))
                            except:
                                pass
                        
                        # Sort by timestamp
                        metrics.sort(key=lambda x: x.get('timestamp', 0), reverse=True)
                        
                        # Get last 100 metrics
                        self.wfile.write(json.dumps(metrics[:100]).encode())
                    else:
                        self.send_error(404)
            
            print(f"Starting dashboard on port {PORT}")
            server = http.server.HTTPServer(('', PORT), MetricsHandler)
            server.serve_forever()
          '';
          
          Restart = "always";
          User = "nobody";
          Group = "nogroup";
        };
      };
      
      # Open firewall port
      networking.firewall.allowedTCPPorts = [ cfg.reporting.dashboardPort ];
    })
    
    # Alerts configuration
    (mkIf (cfg.reporting.enable && cfg.reporting.alerts.enable) {
      systemd.services.nix-performance-alerts = {
        description = "Nix Performance Alert Monitor";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeScript "nix-performance-alerts" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail
            
            # Check disk usage
            STORE_USAGE=$(df /nix/store | tail -1 | awk '{print $5}' | sed 's/%//')
            if [[ $STORE_USAGE -gt ${toString cfg.reporting.alerts.thresholds.diskUsage} ]]; then
              echo "ALERT: Nix store usage at $STORE_USAGE% (threshold: ${toString cfg.reporting.alerts.thresholds.diskUsage}%)"
              ${pkgs.systemd}/bin/systemctl start nix-gc.service || true
            fi
            
            # More alerts can be added here
          '';
        };
      };
      
      systemd.timers.nix-performance-alerts = {
        description = "Nix Performance Alert Timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/15"; # Every 15 minutes
          Persistent = true;
        };
      };
    })
  ]);
}