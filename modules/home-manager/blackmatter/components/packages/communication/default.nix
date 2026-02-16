# Communication & Email Tools Package Set
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.packages.communication;
in {
  options.blackmatter.components.packages.communication = {
    enable = mkEnableOption "communication and email tools package set";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Email clients
      neomutt notmuch # alpine disabled: fails to build with new GCC

      # Chat/IRC clients
      irssi weechat bitlbee

      # News/RSS readers
      newsboat rsstail

      # Social media CLI tools
      toot  # Mastodon client
    ];
  };
}
