# System Monitoring & Administration - Ultimate System Control
{ config, lib, pkgs, ... }:
let
  cfg = config.blackmatter.system.monitoring;
  errors = import ../../../../lib/errors.nix { inherit lib; };
in {
  options.blackmatter.system.monitoring = with lib; {
    enable = mkEnableOption "Comprehensive system monitoring and administration tools";
    
    systemMonitors = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable system monitoring tools";
      };
      
      includeAdvanced = mkOption {
        type = types.bool;
        default = true;
        description = "Include advanced monitors (btop, bottom, etc.)";
      };
      
      includeClassic = mkOption {
        type = types.bool;
        default = true;
        description = "Include classic monitors (htop, top, etc.)";
      };
    };
    
    processManagement = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable process management tools";
      };
      
      includeModern = mkOption {
        type = types.bool;
        default = true;
        description = "Include modern process tools (procs, etc.)";
      };
    };
    
    diskTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable disk analysis tools";
      };
      
      includeAnalyzers = mkOption {
        type = types.bool;
        default = true;
        description = "Include disk usage analyzers";
      };
    };
    
    networkTools = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable network monitoring and tools";
      };
      
      includeSecurity = mkOption {
        type = types.bool;
        default = true;
        description = "Include network security tools";
      };
      
      includeDownloaders = mkOption {
        type = types.bool;
        default = true;
        description = "Include download utilities";
      };
    };
    
    systemInfo = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable system information tools";
      };
      
      includeHardware = mkOption {
        type = types.bool;
        default = true;
        description = "Include hardware information tools";
      };
    };
    
    performanceTools = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable performance testing tools";
      };
    };
  };
  
  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base validation
    {
      assertions = [
        {
          assertion = cfg.systemMonitors.enable || cfg.processManagement.enable || 
                     cfg.diskTools.enable || cfg.networkTools.enable || cfg.systemInfo.enable;
          message = errors.format.formatError (
            errors.types.configError "At least one monitoring category must be enabled" {
              available = "systemMonitors, processManagement, diskTools, networkTools, systemInfo";
            }
          );
        }
      ];
    }
    
    # System Monitors Collection
    (lib.mkIf cfg.systemMonitors.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Classic system monitors
          (lib.optionals cfg.systemMonitors.includeClassic [
            htop                   # Interactive process viewer
            top                    # Traditional process viewer
            atop                   # Advanced system monitor
            iotop                  # I/O usage monitor
            powertop              # Power consumption monitor
            sysstat               # System performance tools (sar, iostat)
          ]) ++
          
          # Modern/Advanced monitors
          (lib.optionals cfg.systemMonitors.includeAdvanced [
            btop                   # Modern htop replacement with GPU support
            bottom                 # Cross-platform graphical process/system monitor
            gotop                  # Terminal based graphical activity monitor
            ytop                   # System monitor written in Rust
            bashtop               # Resource monitor that shows usage and stats
            zenith                # System monitor with histogram graphs
          ]) ++
          
          # Network monitoring
          [
            nethogs               # Network usage monitor per process
            nload                 # Network load monitor
            iftop                 # Network interface monitor
            vnstat                # Network statistics daemon
            speedtest-cli         # Internet speed test
            bandwhich             # Terminal bandwidth utilization tool
          ] ++
          
          # System load and uptime
          [
            uptime                # System uptime
            w                     # Show logged in users
            who                   # Show logged in users (simpler)
            last                  # Show login history
            finger                # User information lookup
          ]
        );
        
      # System monitoring aliases
      environment.shellAliases = {
        mon = "htop";
        monitor = "btop";
        processes = "htop";
        network = "nethogs";
        load = "nload";
        bandwidth = "iftop";
        io = "iotop";
        power = "powertop";
        cpu = "htop -C";
        memory = "htop -M";
        disk-io = "iotop -o";
        net-speed = "speedtest-cli";
        sys-load = "uptime";
        users = "w";
      };
    })
    
    # Process Management Tools
    (lib.mkIf cfg.processManagement.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Modern process tools
          (lib.optionals cfg.processManagement.includeModern [
            procs                  # Modern ps replacement
            pgrep                  # Process grep
            pkill                  # Process kill by name
            killall               # Kill processes by name
            fuser                  # Identify processes using files/sockets
          ]) ++
          
          # Classic process tools
          [
            psmisc                # killall, fuser, pstree
            procps                # ps, top, kill, free, etc.
            lsof                  # List open files
            strace                # System call tracer
            ltrace                # Library call tracer
            gdb                   # GNU debugger
          ] ++
          
          # Process control
          [
            nohup                 # Run commands immune to hangups
            timeout               # Run command with time limit
            parallel              # Execute jobs in parallel
            screen                # Terminal multiplexer (from Round 1)
          ]
        );
        
      # Process management aliases
      environment.shellAliases = {
        ps = "procs";
        psg = "procs | grep";
        psa = "procs --tree";
        psmem = "procs --sortd memory";
        pscpu = "procs --sortd cpu";
        ports = "lsof -i";
        listening = "lsof -i -P | grep LISTEN";
        connections = "lsof -i -P";
        files = "lsof";
        trace = "strace -f";
        debug = "gdb";
      };
    })
    
    # Disk Tools Collection
    (lib.mkIf cfg.diskTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Basic disk tools
          [
            coreutils             # df, du, etc.
            util-linux            # lsblk, mount, etc.
            parted                # Partition editor
            gptfdisk              # GPT partition tools (gdisk)
            dosfstools            # FAT filesystem tools
            e2fsprogs             # ext2/3/4 filesystem tools
          ] ++
          
          # Disk usage analyzers
          (lib.optionals cfg.diskTools.includeAnalyzers [
            ncdu                  # NCurses disk usage (from Round 2)
            du-dust               # Intuitive du replacement (from Round 2)
            duf                   # Better df alternative (from Round 2)
            diskus                # Fast disk usage analyzer (from Round 2)
            gdu                   # Fast disk usage analyzer with console interface
            duc                   # Disk usage analyzer with ncurses interface
          ]) ++
          
          # Disk monitoring and testing
          [
            smartmontools         # Hard drive health monitoring (smartctl)
            hdparm                # Hard drive parameters
            badblocks             # Search for bad blocks
            fio                   # Flexible I/O tester
            iozone                # I/O benchmark
            bonnie                # File system benchmark
          ] ++
          
          # File system tools
          [
            tree                  # Directory tree display (from Round 2)
            file                  # File type detection
            stat                  # File statistics
            find                  # Find files
            locate                # File location database
            updatedb              # Update locate database
          ]
        );
        
      # Disk management aliases
      environment.shellAliases = {
        df = "duf";
        du = "dust";
        usage = "ncdu";
        disk-usage = "gdu";
        disk-info = "lsblk -f";
        mounts = "mount | column -t";
        partitions = "lsblk";
        disk-health = "smartctl -a";
        disk-test = "badblocks -v";
        file-type = "file";
        disk-space = "df -h";
        inodes = "df -i";
      };
    })
    
    # Network Tools Collection
    (lib.mkIf cfg.networkTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # Basic network tools
          [
            inetutils             # ping, telnet, etc.
            iputils               # ping, traceroute, etc.
            nettools              # netstat, route, etc. (deprecated but useful)
            iproute2              # ip, ss, etc. (modern replacement)
            dnsutils              # dig, nslookup, etc.
            whois                 # Domain lookup
            traceroute            # Network path tracing
          ] ++
          
          # Download utilities
          (lib.optionals cfg.networkTools.includeDownloaders [
            curl                  # Command line HTTP client
            wget                  # Web downloader
            aria2                 # Multi-protocol downloader
            rsync                 # File synchronization
            rclone                # Cloud storage sync
            yt-dlp                # YouTube downloader
          ]) ++
          
          # Network security and analysis
          (lib.optionals cfg.networkTools.includeSecurity [
            nmap                  # Network discovery and security scanner
            netcat                # Network Swiss Army knife
            socat                 # Multipurpose relay tool
            tcpdump               # Network packet analyzer
            wireshark-cli         # Command-line network analyzer (tshark)
            mtr                   # Network diagnostic tool (traceroute + ping)
          ]) ++
          
          # Network performance
          [
            iperf3                # Network bandwidth testing
            iperf2                # Alternative network testing
            # hping               # disabled: fails to build with new GCC
            nload                 # Network load monitor (already in monitors)
            slurm                 # Network load monitor
          ] ++
          
          # Web tools
          [
            httpie                # Modern HTTP client
            jq                    # JSON processor
            xmlstarlet            # XML toolkit
            html-xml-utils        # HTML/XML utilities
          ]
        );
        
      # Network tools aliases
      environment.shellAliases = {
        ping = "ping -c 4";
        ping6 = "ping6 -c 4";
        ports = "ss -tuln";
        listening = "ss -tlnp";
        connections = "ss -tuln";
        route = "ip route";
        interfaces = "ip addr show";
        dns = "dig";
        whois-domain = "whois";
        trace = "mtr";
        scan = "nmap";
        download = "aria2c";
        sync = "rsync -avz --progress";
        http = "httpie";
        json = "jq";
        bandwidth-test = "iperf3";
        network-test = "mtr google.com";
      };
    })
    
    # System Information Tools
    (lib.mkIf cfg.systemInfo.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] (
          # System information
          [
            neofetch              # Stylized system information
            screenfetch           # Screenshot + system info
            inxi                  # Comprehensive system information
            hardinfo              # System information and benchmark
            lshw                  # Hardware lister
            dmidecode             # DMI/SMBIOS information
            hostnamectl           # System hostname control
          ] ++
          
          # Hardware information
          (lib.optionals cfg.systemInfo.includeHardware [
            hwinfo                # Hardware detection tool
            lspci                 # PCI device information
            lsusb                 # USB device information
            lscpu                 # CPU information
            lsblk                 # Block device information
            usbutils              # USB utilities
            pciutils              # PCI utilities
          ]) ++
          
          # System details
          [
            uname                 # System information
            uptime                # System uptime
            free                  # Memory usage
            sensors               # Hardware sensors
            acpi                  # ACPI information
            cpufrequtils          # CPU frequency utilities
          ] ++
          
          # Environment information
          [
            env                   # Environment variables
            printenv              # Print environment
            locale                # Locale information
            date                  # Date and time
            cal                   # Calendar
            id                    # User/group information
          ]
        );
        
      # System info aliases
      environment.shellAliases = {
        sysinfo = "inxi -Fxz";
        hardware = "lshw -short";
        cpu = "lscpu";
        memory = "free -h";
        devices = "lspci";
        usb = "lsusb";
        disks = "lsblk";
        temp = "sensors";
        bios = "dmidecode -t bios";
        system = "dmidecode -t system";
        cpu-freq = "cpufreq-info";
        kernel = "uname -a";
        distro = "neofetch --stdout";
        specs = "inxi -F";
        about = "screenfetch";
      };
    })
    
    # Performance Testing Tools (Optional)
    (lib.mkIf cfg.performanceTools.enable {
      environment.systemPackages = with pkgs; 
        errors.recovery.withDefault [] [
          stress                # CPU stress testing
          stress-ng             # Enhanced stress testing
          sysbench              # System benchmark
          memtester             # Memory testing
          cpuburn               # CPU burn-in testing
          prime95               # CPU stress testing
          unixbench             # Unix benchmark suite
        ];
        
      # Performance testing aliases
      environment.shellAliases = {
        stress-cpu = "stress --cpu $(nproc)";
        stress-mem = "stress --vm 1 --vm-bytes 1G";
        benchmark = "sysbench";
        cpu-test = "sysbench cpu run";
        memory-test = "sysbench memory run";
        burn-cpu = "stress-ng --cpu $(nproc) --timeout 60s";
      };
    })
    
    # Integration and Enhancement
    {
      # Enhanced system monitoring setup
      environment.variables = {
        # Better ps output
        PS_FORMAT = "pid,ppid,user,pri,ni,vsz,rss,pcpu,pmem,tty,stat,args";
        
        # History for network commands
        HISTCONTROL = "ignoredups:erasedups";
      };
      
      # Useful system functions
      environment.shellInit = ''
        # System monitoring functions
        sysload() {
          echo "=== System Load ==="
          uptime
          echo
          echo "=== Memory Usage ==="
          free -h
          echo
          echo "=== Disk Usage ==="
          df -h
          echo
          echo "=== Top Processes ==="
          ps aux --sort=-%cpu | head -10
        }
        
        # Network diagnostics
        netdiag() {
          local host="''${1:-google.com}"
          echo "=== Network Diagnostics for $host ==="
          echo "Ping test:"
          ping -c 4 "$host"
          echo
          echo "Trace route:"
          mtr -c 4 "$host"
          echo
          echo "DNS lookup:"
          dig "$host"
        }
        
        # Process monitoring
        procmon() {
          local process="$1"
          if [ -z "$process" ]; then
            echo "Usage: procmon <process_name>"
            return 1
          fi
          watch -n 1 "ps aux | grep '$process' | grep -v grep"
        }
        
        # Quick system status
        status() {
          echo "=== Quick System Status ==="
          echo "Hostname: $(hostname)"
          echo "Uptime: $(uptime -p)"
          echo "Load: $(cat /proc/loadavg)"
          echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
          echo "Disk: $(df -h / | tail -1 | awk '{print $3"/"$2" ("$5")"}')"
          echo "Users: $(who | wc -l)"
        }
        
        # Find large files
        findlarge() {
          local size="''${1:-100M}"
          local path="''${2:-.}"
          find "$path" -type f -size "+$size" -exec ls -lh {} \; | sort -k5 -hr
        }
        
        # Monitor log files
        logwatch() {
          local logfile="''${1:-/var/log/syslog}"
          if [ -f "$logfile" ]; then
            tail -f "$logfile"
          else
            echo "Log file not found: $logfile"
          fi
        }
      '';
      
      # Documentation and man pages
      documentation = {
        enable = true;
        man.enable = true;
        info.enable = true;
      };
    }
  ]);
}