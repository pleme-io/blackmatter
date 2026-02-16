# Refactored Vaultwarden module using base patterns
{ lib, config, pkgs, ... }:
with lib;
let
  base = import ../lib/base.nix { inherit lib config pkgs; };
  cfg = config.blackmatter.components.microservices.vaultwarden;
  
  # Common vaultwarden settings with sensible defaults
  defaultSettings = {
    DOMAIN = "https://vault.local";
    SIGNUPS_ALLOWED = false;
    INVITATIONS_ALLOWED = true;
    SHOW_PASSWORD_HINT = false;
    ROCKET_PORT = 8222;
    WEB_VAULT_ENABLED = true;
  };
in
{
  options.blackmatter.components.microservices.vaultwarden = {
    enable = base.types.mkEnableOption "Vaultwarden password manager";
    
    namespace = mkOption {
      type = types.str;
      default = "vaultwarden";
      description = "Logical namespace for vaultwarden instance";
    };
    
    package = mkOption {
      type = types.package;
      default = pkgs.vaultwarden;
      description = "Vaultwarden package to use";
    };
    
    port = mkOption {
      type = types.port;
      default = 8222;
      description = "Port for Vaultwarden web interface";
    };
    
    domain = mkOption {
      type = types.str;
      default = "https://vault.local";
      description = "Domain for Vaultwarden instance";
    };
    
    database = base.types.mkDatabaseOptions // {
      type = mkOption {
        type = types.enum [ "sqlite3" "mysql" "postgres" ];
        default = "sqlite3";
        description = "Database type for Vaultwarden";
      };
    };
    
    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall port for Vaultwarden";
    };
    
    settings = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Additional Vaultwarden configuration settings";
    };
  };
  
  config = mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      inherit (cfg) package;
      config = mkMerge [
        defaultSettings
        {
          DOMAIN = cfg.domain;
          ROCKET_PORT = cfg.port;
          # Database configuration
          DATABASE_URL = if cfg.database.type == "sqlite3"
            then "{DATADIR}/db.sqlite3"
            else if cfg.database.type == "mysql"
            then "mysql://${cfg.database.user}@${cfg.database.host}/${cfg.database.name}"
            else "postgresql://${cfg.database.user}@${cfg.database.host}/${cfg.database.name}";
        }
        cfg.settings
      ];
    };
    
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };
  };
}