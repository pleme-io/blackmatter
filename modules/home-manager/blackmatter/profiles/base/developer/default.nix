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

    # Service-level MCP servers (zoekt/codesearch/amimori daemons)
    # Other MCP servers (github, k8s, fluxcd, etc.) are in blackmatter-anvil
    blackmatter.components.claude.mcp.zoektMcp.enable = true;
    blackmatter.components.claude.mcp.codesearch.enable = true;
    blackmatter.components.claude.mcp.amimori.enable = true;

    # General MCP server packages (installed to PATH)
    blackmatter.components.claude.mcpPackages.enable = true;

    # Essential package sets
    blackmatter.components.packages.rust-renaissance.enable = true;
  };
}
