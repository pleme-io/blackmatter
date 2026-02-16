# modules/darwin/blackmatter/profiles/macos/system/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.system;
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          system = {
            enable = mkEnableOption "enable Darwin system configuration";

            stateVersion = mkOption {
              type = types.int;
              default = 4;
              description = "Darwin system state version";
            };

            primaryUser = mkOption {
              type = types.str;
              default = "drzzln";
              description = "Primary user for the system";
            };

            keyboard = {
              enableKeyMapping = mkOption {
                type = types.bool;
                default = true;
                description = "Enable keyboard mapping";
              };

              remapCapsLockToEscape = mkOption {
                type = types.bool;
                default = true;
                description = "Remap Caps Lock to Escape";
              };
            };

            keyRepeat = mkOption {
              type = types.int;
              default = 2;
              description = "How fast keys repeat";
            };

            initialKeyRepeat = mkOption {
              type = types.int;
              default = 20;
              description = "Delay before repeating starts";
            };

            disableDocumentation = mkOption {
              type = types.bool;
              default = true;
              description = "Disable all documentation (man, info, doc)";
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    system = {
      stateVersion = cfg.stateVersion;
      primaryUser = cfg.primaryUser;
      keyboard = {
        enableKeyMapping = cfg.keyboard.enableKeyMapping;
        remapCapsLockToEscape = cfg.keyboard.remapCapsLockToEscape;
      };
      defaults = {
        NSGlobalDomain.KeyRepeat = cfg.keyRepeat;
        NSGlobalDomain.InitialKeyRepeat = cfg.initialKeyRepeat;
      };
    };

    # Documentation settings
    documentation.enable = !cfg.disableDocumentation;
    documentation.info.enable = !cfg.disableDocumentation;
    documentation.doc.enable = !cfg.disableDocumentation;
    documentation.man.enable = !cfg.disableDocumentation;

    # Enable zsh
    programs.zsh.enable = true;

    # NixBld group ID (Darwin-specific)
    ids.gids.nixbld = 350;
  };
}
