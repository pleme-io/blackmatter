# modules/home-manager/blackmatter/components/attic-netrc/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.atticNetrc;
in {
  options = {
    blackmatter = {
      components = {
        atticNetrc = {
          enable = mkEnableOption "Attic binary cache netrc authentication";

          hostname = mkOption {
            type = types.str;
            description = "Attic cache hostname for netrc authentication";
            example = "cache.example.com";
          };

          login = mkOption {
            type = types.str;
            default = "attic";
            description = "Login username for Attic cache";
          };

          password = mkOption {
            type = types.str;
            description = "Authentication token/password for Attic cache";
            example = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.file.".config/nix/netrc".text = ''
      machine ${cfg.hostname}
      login ${cfg.login}
      password ${cfg.password}
    '';
  };
}
