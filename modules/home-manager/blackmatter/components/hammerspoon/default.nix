# modules/home-manager/blackmatter/components/hammerspoon/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.hammerspoon;
in {
  options = {
    blackmatter = {
      components = {
        hammerspoon = {
          enable = mkEnableOption "Hammerspoon macOS automation configuration";

          initLua = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to Hammerspoon init.lua file";
            example = "./hammerspoon-init.lua";
          };

          initContent = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = "Direct Lua content for Hammerspoon init.lua (alternative to initLua)";
            example = ''
              hs.hotkey.bind({"cmd"}, "space", function()
                hs.eventtap.keyStroke({"cmd"}, "space", 0)
              end)
            '';
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.initLua != null) != (cfg.initContent != null);
        message = "Exactly one of initLua or initContent must be set for Hammerspoon configuration";
      }
    ];

    home.file.".hammerspoon/init.lua" =
      if cfg.initLua != null
      then {source = cfg.initLua;}
      else {text = cfg.initContent;};
  };
}
