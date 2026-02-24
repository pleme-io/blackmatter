# Centralized development environment variable management.
# Single source of truth for all session variables.
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.env;
in {
  options.blackmatter.components.env = {
    enable = mkEnableOption "centralized environment variables";

    variables = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Literal environment variables (set directly in hm-session-vars.sh)";
    };

    secretFiles = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = ''
        File-backed environment variables. Keys are var names, values are file paths.
        Each var is set to the file contents at shell startup via command substitution.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.sessionVariables =
      cfg.variables
      // (mapAttrs (_: path: "$(cat ${path} 2>/dev/null || true)") cfg.secretFiles);
  };
}
