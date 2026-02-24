# modules/nixos/blackmatter/components/system-locale/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.systemLocale;
in {
  options.blackmatter.components.systemLocale = {
    enable = mkEnableOption "system locale configuration";

    defaultLocale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "Default locale for the system";
      example = "pt_BR.UTF-8";
    };

    extraLocaleSettings = mkOption {
      type = types.attrsOf types.str;
      default = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
      description = "Extra locale settings for specific categories";
      example = lib.literalExpression ''
        {
          LC_ADDRESS = "pt_BR.UTF-8";
          LC_MONETARY = "pt_BR.UTF-8";
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    i18n.defaultLocale = cfg.defaultLocale;
    i18n.extraLocaleSettings = cfg.extraLocaleSettings;
  };
}
