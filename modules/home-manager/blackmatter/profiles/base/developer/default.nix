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

    # Claude Code configuration (LSP + MCP servers)
    blackmatter.components.claude.enable = true;

    # MCP servers for AI-assisted development
    # Zoekt/codesearch daemons are managed by their own repos (zoekt-mcp, codesearch)
    # and configured per-machine in the nix repo via services.zoekt.daemon / services.codesearch.daemon
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
