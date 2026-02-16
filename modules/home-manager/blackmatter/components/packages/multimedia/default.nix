# Multimedia CLI/TUI Tools Package Set
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.packages.multimedia;
in {
  options.blackmatter.components.packages.multimedia = {
    enable = mkEnableOption "multimedia CLI/TUI tools package set";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Core multimedia tools
      figlet toilet boxes cowsay fortune lolcat
      yt-dlp mpv ffmpeg sox
      imagemagick feh pandoc
      neofetch cmatrix sl

      # Audio/video tools
      cmus aria2 streamlink mediainfo exiftool
      qrencode groff aspell
    ];
  };
}
