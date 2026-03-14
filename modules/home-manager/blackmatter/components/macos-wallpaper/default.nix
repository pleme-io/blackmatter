# macOS wallpaper management via NSWorkspace API.
#
# Sets the desktop wallpaper on all screens using AppKit's
# setDesktopImageURL, then restarts WallpaperAgent to flush
# the macOS display cache. Works on Sequoia, Tahoe, and later
# — handles both static and dynamic (video) wallpaper overrides.
#
# The image source is a Nix path (derivation or local file).
# It gets copied to ~/Pictures/wallpaper.jpg on every activation
# because macOS ignores Nix store symlinks.
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.macos-wallpaper;
in {
  options.blackmatter.components.macos-wallpaper = {
    enable = mkEnableOption "macOS wallpaper management";

    image = mkOption {
      type = types.path;
      default = ./wallpaper.jpg;
      description = "Path to the wallpaper image (JPEG or PNG). Copied to ~/Pictures/ on activation.";
    };

    target = mkOption {
      type = types.str;
      default = "Pictures/wallpaper.jpg";
      description = "Destination path relative to $HOME for the wallpaper copy.";
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    home.activation.setWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      _wp="${config.home.homeDirectory}/${cfg.target}"
      mkdir -p "$(dirname "$_wp")"
      cp -f "${cfg.image}" "$_wp"
      /usr/bin/osascript -e '
        use framework "AppKit"
        set wp to current application'\'''s NSWorkspace'\'''s sharedWorkspace()
        set allScreens to current application'\'''s NSScreen'\'''s screens()
        set theURL to current application'\'''s |NSURL|'\'''s fileURLWithPath:"'"$_wp"'"
        set theOptions to current application'\'''s NSDictionary'\'''s dictionary()
        repeat with scr in allScreens
          wp'\'''s setDesktopImageURL:theURL forScreen:scr options:theOptions |error|:(missing value)
        end repeat
      '
      killall WallpaperAgent 2>/dev/null || true
    '';
  };
}
