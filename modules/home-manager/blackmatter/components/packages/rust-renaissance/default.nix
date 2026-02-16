# Modern CLI Alternatives (Rust Renaissance) Package Set
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.packages.rust-renaissance;
in {
  options.blackmatter.components.packages.rust-renaissance = {
    enable = mkEnableOption "modern Rust-based CLI alternatives package set";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Modern file tools
      bat fd ripgrep eza dust tokei

      # Modern system tools
      procs bottom bandwhich grex

      # Modern utilities
      hyperfine just sd jq

      # Modern network tools
      dog gping httpie
    ];
  };
}
