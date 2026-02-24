{
  lib,
  ...
}:
with lib; {
  # Extracted components (nvim, shell, claude, desktop, security, kubernetes)
  # are imported at the flake level via homeManagerModules.blackmatter.
  # Only inline (small, rarely-changing) components are imported here.
  imports = [
    ./attic-netrc
    ./env
    ./ghostty
    ./gitconfig
    ./hammerspoon
    ./mcp
    ./microservices
    ./packages
    ./ssh
    ./ssh-aliases
  ];

  options = {
    blackmatter = {
      components = {
        enable = mkEnableOption "enable blackmatter components";
      };
    };
  };
}
