# Fix ghostty terminfo collision with ncurses
# ghostty provides its own terminfo which conflicts with ncurses
# Solution: don't install terminfo from ghostty since ncurses provides it
final: prev: {
  ghostty = (prev.ghostty.override {
    # Use a wrapper that excludes the terminfo output to avoid collision
  }).overrideAttrs (old: {
    # Filter out the terminfo output to prevent collision with ncurses
    outputs = builtins.filter (x: x != "terminfo") (old.outputs or ["out"]);

    postInstall = (old.postInstall or "") + ''
      # Don't create terminfo directory since we removed the output
      # and ncurses already provides the ghostty terminfo entry
      if [ -d "$out/share/terminfo" ]; then
        rm -rf $out/share/terminfo
      fi
    '';

    postFixup = (old.postFixup or "") + ''
      # Remove any symlinks to terminfo that may have been created
      if [ -L "$out/share/terminfo" ]; then
        rm -f "$out/share/terminfo"
      fi
    '';
  });
}
