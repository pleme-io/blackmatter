# modules/darwin/blackmatter/profiles/macos/maintenance/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.maintenance;

  # Build the cleanup script with configured paths and maxDepth
  cleanupScript = pkgs.writeShellScript "rust-artifact-cleanup" ''
    set -euo pipefail
    total_freed=0

    SCAN_PATHS=(${concatStringsSep " " (map (p: ''"${p}"'') cfg.rustCleanup.paths)})
    MAX_DEPTH=${toString cfg.rustCleanup.maxDepth}

    for scan_dir in "''${SCAN_PATHS[@]}"; do
      [ -d "$scan_dir" ] || continue
      while IFS= read -r -d "" target_dir; do
        parent="$(dirname "$target_dir")"
        # Validate: sibling Cargo.toml OR target contains release/debug/.cargo-lock
        if [ -f "$parent/Cargo.toml" ] || \
           [ -d "$target_dir/debug" ] || \
           [ -d "$target_dir/release" ] || \
           [ -f "$target_dir/.cargo-lock" ]; then
          size=$(du -sm "$target_dir" 2>/dev/null | cut -f1)
          rm -rf "$target_dir"
          total_freed=$((total_freed + size))
          /usr/bin/logger -t rust-cleanup "Removed $target_dir (''${size}MB)"
        fi
      done < <(find "$scan_dir" -maxdepth "$MAX_DEPTH" -name target -type d -print0 2>/dev/null)
    done

    /usr/bin/logger -t rust-cleanup "Total freed: ''${total_freed}MB"
  '';
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          maintenance = {
            enable = mkEnableOption "macOS maintenance tasks";

            rustCleanup = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Enable periodic cleanup of Rust target/ directories";
              };

              paths = mkOption {
                type = types.listOf types.str;
                default = [];
                example = ["/Users/drzzln/code"];
                description = "Directories to scan for Rust target/ dirs";
              };

              maxDepth = mkOption {
                type = types.int;
                default = 5;
                description = "How deep to search for target/ dirs (performance guard)";
              };

              interval = mkOption {
                type = types.attrs;
                default = {Weekday = 7; Hour = 3; Minute = 0;};
                description = "LaunchDaemon schedule. Default: Sundays at 3 AM.";
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Rust artifact cleanup daemon
    launchd.daemons.rust-artifact-cleanup = mkIf (cfg.rustCleanup.enable && cfg.rustCleanup.paths != []) {
      serviceConfig = {
        Label = "org.nixos.rust-artifact-cleanup";
        ProgramArguments = ["/bin/bash" "${cleanupScript}"];
        StartCalendarInterval = cfg.rustCleanup.interval;
        RunAtLoad = false;
        LowPriorityIO = true;
        Nice = 15;
        StandardErrorPath = "/tmp/rust-cleanup.err";
        StandardOutPath = "/tmp/rust-cleanup.log";
      };
    };
  };
}
