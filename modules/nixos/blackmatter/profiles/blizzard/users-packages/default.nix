# modules/nixos/blackmatter/profiles/blizzard/users-packages/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard.usersPackages;
  profileCfg = config.blackmatter.profiles.blizzard;
in {
  options.blackmatter.profiles.blizzard.usersPackages = {
    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          uid = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "User ID";
          };

          description = mkOption {
            type = types.str;
            default = "";
            description = "User description";
          };

          shell = mkOption {
            type = types.package;
            default = pkgs.bash;
            description = "User shell";
          };

          isNormalUser = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this is a normal user account";
          };

          extraGroups = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Additional groups for this user";
          };

          packages = mkOption {
            type = types.listOf types.package;
            default = [];
            description = "Packages to install for this user";
          };

          sudoNoPassword = mkOption {
            type = types.bool;
            default = false;
            description = "Allow passwordless sudo for this user";
          };
        };
      });
      default = {};
      description = "User account configurations";
      example = literalExpression ''
        {
          "john" = {
            uid = 1001;
            description = "John Doe";
            shell = pkgs.zsh;
            extraGroups = ["wheel" "docker"];
            sudoNoPassword = true;
          };
        }
      '';
    };

    systemPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "System-wide packages to install";
    };

    developmentPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Development tools (installed only for workstation and headless-dev variants)";
    };

    allowUnfree = mkOption {
      type = types.bool;
      default = false;
      description = "Allow unfree packages";
    };

    allowBroken = mkOption {
      type = types.bool;
      default = false;
      description = "Allow broken packages";
    };

    allowImportFromDerivation = mkOption {
      type = types.bool;
      default = false;
      description = "Allow import from derivation (IFD)";
    };

    permittedInsecurePackages = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of insecure packages to permit";
    };

    overlays = mkOption {
      type = types.listOf types.unspecified;
      default = [];
      description = "Nixpkgs overlays to apply";
    };
  };

  config = mkIf profileCfg.enable (mkMerge [
    {
      users.users = mapAttrs (name: user: {
        uid = mkIf (user.uid != null) user.uid;
        description = user.description;
        shell = user.shell;
        isNormalUser = user.isNormalUser;
        extraGroups = user.extraGroups;
        packages = user.packages;
      }) cfg.users;

      security.sudo.extraConfig = concatStrings (
        mapAttrsToList (name: user:
          optionalString user.sudoNoPassword ''
            ${name} ALL=(ALL) NOPASSWD:ALL
          '')
          cfg.users
      );

      environment.systemPackages = cfg.systemPackages;

      nixpkgs.config = {
        allowUnfree = cfg.allowUnfree;
        allowBroken = cfg.allowBroken;
        allowImportFromDerivation = cfg.allowImportFromDerivation;
        permittedInsecurePackages = cfg.permittedInsecurePackages;
      };

      nixpkgs.overlays = cfg.overlays;
    }

    # Install development tools only for workstation, workstation-agent, and headless-dev variants
    (mkIf (profileCfg.variant == "workstation" || profileCfg.variant == "workstation-agent" || profileCfg.variant == "headless-dev") {
      environment.systemPackages = cfg.developmentPackages;
    })
  ]);
}
