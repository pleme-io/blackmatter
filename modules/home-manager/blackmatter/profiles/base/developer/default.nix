# Base Developer Profile - Minimal development environment
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.base.developer;
in {
  options.blackmatter.profiles.base.developer = {
    enable = mkEnableOption "developer base profile";
  };

  config = mkIf cfg.enable {
    # Core components
    blackmatter.components.nvim.enable = true;
    blackmatter.components.shell.enable = true;
    blackmatter.components.shell.packages.enable = true; # Includes claude-code, ripgrep, etc.
    blackmatter.components.gitconfig.enable = true;

    # Claude Code configuration (LSP servers)
    blackmatter.components.claude.enable = true;

    # Zoekt code search daemon — indexes repos for instant trigram search
    blackmatter.components.claude.zoekt = {
      enable = true;
      repos = [
        "/Users/drzzln/code/github/pleme-io/nexus"
        "/Users/drzzln/code/github/pleme-io/codesearch"
        "/Users/drzzln/code/github/drzln/pangea"
        "/Users/drzzln/code/github/drzln/z9s"
        "/Users/drzzln/code/github/drzln/vision"
        "/Users/drzzln/code/nix-refs/nixpkgs"
        "/Users/drzzln/code/nix-refs/home-manager"
        "/Users/drzzln/code/nix-refs/nix-darwin"
      ];
    };

    # Codesearch daemon — semantic code search with live file watching
    blackmatter.components.claude.codesearch = {
      enable = true;
      repos = [
        "/Users/drzzln/code/github/pleme-io/nexus"
        "/Users/drzzln/code/github/pleme-io/codesearch"
        "/Users/drzzln/code/github/drzln/pangea"
        "/Users/drzzln/code/github/drzln/z9s"
        "/Users/drzzln/code/github/drzln/vision"
      ];
    };

    # MCP servers for AI-assisted development
    blackmatter.components.claude.mcp.zoektMcp.enable = true;
    blackmatter.components.claude.mcp.codesearch.enable = true;
    blackmatter.components.claude.mcp.github.enable = true;
    blackmatter.components.claude.mcp.kubernetes.enable = true;
    blackmatter.components.claude.mcp.fluxcd.enable = true;

    # General MCP server packages (installed to PATH)
    blackmatter.components.mcp.enable = true;

    # Essential package sets
    blackmatter.components.packages.rust-renaissance.enable = true;
  };
}
