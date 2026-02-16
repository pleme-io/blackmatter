# Base secrets management patterns
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  # Common secret types and helpers
  types = {
    # Create a standard secret option
    mkSecretOption = {
      name,
      description ? "Secret for ${name}",
      ...
    } @ args:
      mkOption ({
          type = types.attrs;
          default = {};
          description = description;
        }
        // removeAttrs args ["name" "description"]);

    # Standard secret path option
    secretPath = mkOption {
      type = types.path;
      description = "Path to the secret file";
    };

    # Standard secret format
    secretFormat = mkOption {
      type = types.enum ["plain" "json" "yaml" "env"];
      default = "plain";
      description = "Format of the secret file";
    };
  };

  # Common patterns for secrets
  patterns = {
    # Create a standard sops secret definition
    mkSopsSecret = {
      name,
      owner ? "root",
      group ? "root",
      mode ? "0400",
      path ? null,
      sopsFile,
    }:
      {
        inherit mode owner group sopsFile;
      }
      // optionalAttrs (path != null) {inherit path;};

    # Create multiple secrets with same settings
    mkSopsSecrets = {
      names,
      owner ? "root",
      group ? "root",
      mode ? "0400",
      sopsFile,
    }:
      listToAttrs (map (name: {
          inherit name;
          value = mkSopsSecret {inherit name owner group mode sopsFile;};
        })
        names);

    # Create service-specific secrets
    mkServiceSecrets = {
      service,
      secrets,
      owner ? service,
      group ? service,
      mode ? "0400",
      sopsFile,
    }:
      mkSopsSecrets {
        names = map (secret: "${service}/${secret}") secrets;
        inherit owner group mode sopsFile;
      };
  };

  # Helper functions
  helpers = {
    # Get secret path
    getSecretPath = name: config.sops.secrets.${name}.path;

    # Check if secret exists
    hasSecret = name: config.sops.secrets ? ${name};

    # Create environment file from secrets
    mkEnvFile = secrets: let
      lines = mapAttrsToList (name: path: "${name}=$(cat ${path})") secrets;
    in
      pkgs.writeText "env-file" (concatStringsSep "\n" lines);

    # Validate secret configuration
    validateSecret = {
      name,
      requiredKeys ? [],
      format ? "plain",
    }: secret: let
      errors = [];
      checkKeys =
        if format == "json" || format == "yaml"
        then filter (key: !hasAttr key secret) requiredKeys
        else [];
    in
      if checkKeys != []
      then throw "Secret ${name} missing required keys: ${concatStringsSep ", " checkKeys}"
      else secret;
  };

  # Common secret configurations
  configs = {
    # Database credentials
    database = {
      postgres = owner:
        mkSopsSecrets {
          names = ["password" "username" "database"];
          inherit owner;
          group = owner;
          mode = "0400";
        };

      mysql = owner:
        mkSopsSecrets {
          names = ["password" "username" "database" "root_password"];
          inherit owner;
          group = owner;
          mode = "0400";
        };

      redis = owner:
        mkSopsSecret {
          name = "password";
          inherit owner;
          group = owner;
          mode = "0400";
        };
    };

    # API keys
    apiKeys = {
      simple = name: owner:
        mkSopsSecret {
          inherit name owner;
          group = owner;
          mode = "0400";
        };

      withEndpoint = name: owner:
        mkSopsSecrets {
          names = ["${name}/key" "${name}/endpoint"];
          inherit owner;
          group = owner;
          mode = "0400";
        };
    };

    # TLS certificates
    tls = {
      cert = name:
        mkSopsSecrets {
          names = ["${name}/cert" "${name}/key"];
          owner = "root";
          group = "root";
          mode = "0444";
        };

      ca = name:
        mkSopsSecret {
          name = "${name}/ca";
          owner = "root";
          group = "root";
          mode = "0444";
        };
    };

    # Service accounts
    serviceAccount = service:
      mkSopsSecrets {
        names = ["${service}/username" "${service}/password"];
        owner = service;
        group = service;
        mode = "0400";
      };
  };

  # Rotation helpers
  rotation = {
    # Mark secret for rotation
    markForRotation = name: {
      "${name}".restartUnits = ["${name}-rotate.service"];
    };

    # Create rotation timer
    mkRotationTimer = {
      name,
      interval ? "monthly",
      onCalendar ? "*-*-01 00:00:00",
    }: {
      "systemd.timers.${name}-rotate" = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = onCalendar;
          Persistent = true;
        };
      };

      "systemd.services.${name}-rotate" = {
        description = "Rotate ${name} secrets";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl restart ${name}";
        };
      };
    };
  };

  # Assertions for common secret requirements
  assertions = {
    # Ensure required secrets exist
    requireSecrets = names:
      map (name: {
        assertion = config.sops.secrets ? ${name};
        message = "Required secret '${name}' is not defined";
      })
      names;

    # Ensure secret has required permissions
    checkPermissions = {
      name,
      owner,
      group,
      maxMode ? "0600",
    }: {
      assertion = let
        secret = config.sops.secrets.${name};
      in
        secret.owner
        == owner
        && secret.group == group
        && (toInt secret.mode) <= (toInt maxMode);
      message = "Secret '${name}' has incorrect permissions";
    };
  };
}

