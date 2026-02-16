# Specialized Tools & Terminal Enhancements Package Set
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.packages.specialized;
in {
  options.blackmatter.components.packages.specialized = {
    enable = mkEnableOption "specialized tools and terminal enhancements package set";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Terminal emulators
      kitty wezterm foot

      # Terminal utilities
      tmate abduco

      # ASCII art and fun
      asciiquarium

      # Data processing tools
      miller csvkit xmlstarlet

      # Web browsers
      w3m

      # Performance testing tools
      stress iperf sysbench
    ];
  };
}
