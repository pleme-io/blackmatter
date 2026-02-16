# Development tool overlays
final: prev: {
  # Custom neovim
  neovim-custom = prev.callPackage ../../pkgs/neovim {
    msgpack-c = prev.msgpack-c;
  };
  
  # Node.js development bundle
  nodejs-dev = prev.buildEnv {
    name = "nodejs-dev";
    paths = with prev; [
      nodejs
      yarn
      nodePackages.pnpm
      nodePackages.typescript
      nodePackages.typescript-language-server
      nodePackages.prettier
      nodePackages.eslint
    ];
  };
  
  # Python development bundle
  python-dev = prev.buildEnv {
    name = "python-dev";
    paths = with prev; [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      python3Packages.black
      python3Packages.pylint
      python3Packages.pytest
      python3Packages.ipython
    ];
  };
  
  # Rust development bundle
  rust-dev = prev.buildEnv {
    name = "rust-dev";
    paths = with prev; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
      cargo-edit
      cargo-watch
      cargo-audit
    ];
  };
  
  # Go development bundle
  go-dev = prev.buildEnv {
    name = "go-dev";
    paths = with prev; [
      go
      gopls
      gotools
      go-tools
      golangci-lint
      delve
    ];
  };
  
  # Code formatters bundle
  code-formatters = prev.buildEnv {
    name = "code-formatters";
    paths = with prev; [
      nixpkgs-fmt
      black
      rustfmt
      gofmt
      prettier
      shfmt
      stylua
    ];
  };
  
  # Language servers bundle
  language-servers = prev.buildEnv {
    name = "language-servers";
    paths = with prev; [
      nil # Nix
      rust-analyzer
      gopls
      nodePackages.typescript-language-server
      python3Packages.python-lsp-server
      lua-language-server
      yaml-language-server
    ];
  };
  
  # Enhanced git
  git-enhanced = prev.git.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      # Add useful git aliases
      mkdir -p $out/share/git-core/templates
      cat > $out/share/git-core/templates/config << 'EOF'
      [alias]
        st = status -sb
        co = checkout
        br = branch
        ci = commit
        unstage = reset HEAD --
        last = log -1 HEAD
        visual = !gitk
      EOF
    '';
  });
  
  # Enhanced tmux
  tmux-enhanced = prev.tmux.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      # Add tmux plugin manager
      mkdir -p $out/share/tmux-plugins
    '';
  });
}