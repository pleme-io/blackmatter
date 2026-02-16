# Productivity tool overlays
final: prev: {
  # Shell productivity bundle
  shell-productivity = prev.buildEnv {
    name = "shell-productivity";
    paths = with prev; [
      fzf
      zoxide
      bat
      eza
      fd
      ripgrep
      jq
      yq
      delta
      tokei
      hyperfine
      just
    ];
  };
  
  # Task management bundle
  task-tools = prev.buildEnv {
    name = "task-tools";
    paths = with prev; [
      taskwarrior3
    ] ++ prev.lib.optionals (prev ? taskwarrior-tui) [
      taskwarrior-tui
    ];
  };
  
  # Enhanced fzf with better defaults
  fzf-enhanced = prev.fzf.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      # Add default configuration
      mkdir -p $out/share/fzf
      cat > $out/share/fzf/default-config << 'EOF'
      export FZF_DEFAULT_OPTS="
        --height 40%
        --layout reverse
        --border rounded
        --inline-info
        --color 'fg:#bbccdd,fg+:#ddeeff,bg:#334455,preview-bg:#223344,border:#778899'
      "
      export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
      export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
      EOF
    '';
  });
  
  # Document processing bundle
  doc-tools = prev.buildEnv {
    name = "doc-tools";
    paths = with prev; [
      pandoc
      texlive.combined.scheme-medium
      libreoffice
      zathura
    ] ++ prev.lib.optionals (prev ? okular) [
      okular
    ];
  };
  
  # Media productivity bundle
  media-productivity = prev.buildEnv {
    name = "media-productivity";
    paths = with prev; [
      ffmpeg
      imagemagick
      gimp
      inkscape
    ] ++ prev.lib.optionals prev.stdenv.isLinux [
      obs-studio
      kdenlive
    ];
  };
  
  # System monitoring bundle
  monitoring-tools = prev.buildEnv {
    name = "monitoring-tools";
    paths = with prev; [
      htop
      btop
      iotop
      nethogs
      bmon
    ] ++ prev.lib.optionals (prev ? s-tui) [
      s-tui
    ];
  };
  
  # Communication tools bundle
  comm-tools = prev.buildEnv {
    name = "comm-tools";
    paths = with prev; [
      slack
      discord
      signal-desktop
    ] ++ prev.lib.optionals (prev ? element-desktop) [
      element-desktop
    ] ++ prev.lib.optionals (prev ? zoom-us) [
      zoom-us
    ];
  };
}