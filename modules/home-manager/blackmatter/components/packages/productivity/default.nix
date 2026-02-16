# Productivity & Task Management Tools Package Set
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.packages.productivity;
in {
  options.blackmatter.components.packages.productivity = {
    enable = mkEnableOption "productivity and task management tools package set";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Task management
      taskwarrior3 timewarrior calcurse remind

      # Note taking
      joplin nb

      # Calendar and scheduling
      when # gcal - Disabled: GCC 15 build issues

      # Calculators
      bc libqalculate
    ];
  };
}
