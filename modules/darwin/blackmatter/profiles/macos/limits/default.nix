# modules/darwin/blackmatter/profiles/macos/limits/default.nix
# Configures file descriptor and process limits for macOS
# Required for Nix builds which open many files simultaneously
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.limits;
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          limits = {
            enable = mkEnableOption "enable macOS resource limits configuration";

            # Canonical fleet ceiling = 2^24 (16,777,216) open files per
            # process — max headroom by default everywhere (operator decision
            # 2026-06-30). launchctl bounds `hard` by kern.maxfiles, which the
            # nix-repo pleme.darwin.profiles.developerResources sysctl raises to
            # 2^25 (33,554,432). Peer faces: NixOS
            # blackmatter.components.systemLimits + HM
            # blackmatter.components.fdLimits.
            maxfiles = {
              soft = mkOption {
                type = types.int;
                default = 16777216;
                description = "Soft limit for maximum open files";
              };

              hard = mkOption {
                type = types.int;
                default = 16777216;
                description = "Hard limit for maximum open files";
              };
            };

            maxproc = {
              soft = mkOption {
                type = types.int;
                default = 2048;
                description = "Soft limit for maximum processes";
              };

              hard = mkOption {
                type = types.int;
                default = 4096;
                description = "Hard limit for maximum processes";
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Set kernel-level file limits
    # These affect the entire system
    launchd.daemons.limit-maxfiles = {
      serviceConfig = {
        Label = "limit.maxfiles";
        ProgramArguments = [
          "/bin/launchctl"
          "limit"
          "maxfiles"
          (toString cfg.maxfiles.soft)
          (toString cfg.maxfiles.hard)
        ];
        RunAtLoad = true;
      };
    };

    launchd.daemons.limit-maxproc = {
      serviceConfig = {
        Label = "limit.maxproc";
        ProgramArguments = [
          "/bin/launchctl"
          "limit"
          "maxproc"
          (toString cfg.maxproc.soft)
          (toString cfg.maxproc.hard)
        ];
        RunAtLoad = true;
      };
    };
  };
}
