# modules/nixos/blackmatter/components/docker-optimizations/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.dockerOptimizations;
in {
  options.blackmatter.components.dockerOptimizations = {
    enable = mkEnableOption "Docker service limit optimizations";
  };

  config = mkIf cfg.enable {
    systemd.services.docker.serviceConfig = {
      LimitNOFILE = "1048576";
      LimitNPROC = "65536";
      LimitSTACK = "infinity";
      LimitMEMLOCK = "infinity";
    };
    systemd.user.services.docker.serviceConfig = {
      # competes with virtualisation values
      # LimitNOFILE = 1048576;
      # LimitNPROC = 65536;
      LimitSTACK = "infinity";
      LimitMEMLOCK = "infinity";
    };
    systemd.settings.Manager = {
      DefaultLimitNOFILE = mkDefault 1048576;
      DefaultLimitNPROC = mkDefault 65536;
      DefaultLimitSTACK = mkDefault "infinity";
      DefaultLimitMEMLOCK = mkDefault "infinity";
    };
    environment.etc."docker/daemon.json".text = ''
      {
        "default-ulimits": {
          "nofile": {
            "Name": "nofile",
            "Soft": 1048576,
            "Hard": 1048576
          },
          "nproc": {
            "Name": "nproc",
            "Soft": 65536,
            "Hard": 65536
          }
        }
      }'';
  };
}
