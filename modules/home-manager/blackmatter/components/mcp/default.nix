# MCP (Model Context Protocol) Servers - Comprehensive MCP server management
#
# This module controls the installation of ALL available MCP servers across all nodes.
# Each server can be individually disabled if needed, but all are enabled by default.
#
# Note: Some packages are Linux-only and will be skipped on Darwin.
#
# Categories:
#   - Nix ecosystem (nixos) [Linux only]
#   - Version control (github, gitea)
#   - Cloud/Infrastructure (kubernetes, aks, grafana, terraform, fluxcd)
#   - Browser automation (playwright)
#   - Development tools (languageServer)
#   - MCP infrastructure (mcphost, toolhive, proxy [Linux], chatmcp [Linux])
#   - SDKs and libraries (Python ecosystem) [Linux only]
#   - Haskell ecosystem (disabled by default - often broken)
#
# Usage with Claude Code:
#   claude mcp add --transport stdio --scope user nixos -- mcp-nixos
#   claude mcp add --transport stdio --scope user github -- github-mcp-server
#
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.mcp;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
in {
  options.blackmatter.components.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) servers";

    # ============================================================================
    # NIX ECOSYSTEM (Linux only)
    # ============================================================================
    nixos = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "mcp-nixos - Search 130K+ NixOS packages, 23K+ options, Home Manager, nix-darwin, Nixvim (native on Linux, via uvx on Darwin)";
      };
    };

    # ============================================================================
    # VERSION CONTROL
    # ============================================================================
    github = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "github-mcp-server - GitHub's official MCP server for repos, issues, PRs";
      };
    };

    gitea = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "gitea-mcp-server - Gitea/Forgejo MCP server";
      };
    };

    # ============================================================================
    # CLOUD & INFRASTRUCTURE
    # ============================================================================
    kubernetes = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "mcp-k8s-go - Kubernetes cluster integration";
      };
    };

    aks = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "aks-mcp-server - Azure Kubernetes Service integration";
      };
    };

    grafana = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "mcp-grafana - Grafana dashboards and monitoring integration";
      };
    };

    terraform = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "terraform-mcp-server - Terraform/OpenTofu Infrastructure as Code";
      };
    };

    fluxcd = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "fluxcd-operator-mcp - FluxCD GitOps lifecycle management";
      };
    };

    # ============================================================================
    # DATASOURCE MCP SERVERS (via npx - not yet in nixpkgs)
    # ============================================================================
    postgres = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "@modelcontextprotocol/server-postgres - Official PostgreSQL MCP server for schema inspection and read-only queries (via npx)";
      };
    };

    loki = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "grafana/loki-mcp - Direct Loki LogQL queries and log exploration (via npx)";
      };
    };

    graphql = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "mcp-graphql - GraphQL schema introspection and query execution (via npx)";
      };
    };

    redis = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "@modelcontextprotocol/server-redis - Official Redis/Valkey MCP server for key-value operations (via npx)";
      };
    };

    # ============================================================================
    # BROWSER AUTOMATION
    # ============================================================================
    playwright = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "playwright-mcp - Browser automation via accessibility snapshots";
      };
    };

    # ============================================================================
    # DEVELOPMENT TOOLS
    # ============================================================================
    languageServer = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "mcp-language-server - Interact with any LSP-compatible language server";
      };
    };

    # ============================================================================
    # MCP INFRASTRUCTURE & UTILITIES
    # ============================================================================
    mcphost = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "mcphost - CLI host enabling LLMs to use MCP tools";
      };
    };

    toolhive = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "toolhive - Run any MCP server securely, instantly, anywhere";
      };
    };

    proxy = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "mcp-proxy - Proxy MCP servers between stdio and SSE transports (Linux only)";
      };
    };

    chatmcp = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "chatmcp - AI chat client implementing MCP (Linux only)";
      };
    };

    # ============================================================================
    # PYTHON MCP ECOSYSTEM (Linux only, disabled by default - python3.13 compat issues)
    # ============================================================================
    pythonSdk = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "python3Packages.mcp - Official Python SDK for MCP servers and clients (Linux only)";
      };
    };

    fastmcp = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "python3Packages.fastmcp - Fast, Pythonic way to build MCP servers (Linux only)";
      };
    };

    mcpadapt = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "python3Packages.mcpadapt - MCP servers adaptation tool (Linux only)";
      };
    };

    docling = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "python3Packages.docling-mcp - Document processing made agentic through MCP (Linux only)";
      };
    };

    fastapiMcp = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "python3Packages.fastapi-mcp - Expose FastAPI endpoints as MCP tools (Linux only)";
      };
    };

    djangoMcp = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "python3Packages.django-mcp-server - Django MCP server implementation (Linux only)";
      };
    };

    # ============================================================================
    # HASKELL MCP ECOSYSTEM (disabled by default - packages often broken)
    # ============================================================================
    haskellMcp = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "haskellPackages.mcp - Haskell implementation of MCP (often broken)";
      };
    };

    haskellMcpServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "haskellPackages.mcp-server - Library for building MCP servers in Haskell (often broken)";
      };
    };

    ptyMcpServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "haskellPackages.pty-mcp-server - PTY-based MCP server (often broken)";
      };
    };
  };

  config = mkIf cfg.enable (let
    # Helper: only include package if it exists in pkgs (many MCP servers not yet in nixpkgs)
    optPkg = name: if builtins.hasAttr name pkgs then [pkgs.${name}] else [];
    optPkgIf = cond: name: optionals cond (optPkg name);
  in {
    home.packages = with pkgs;
      # NIX ECOSYSTEM
      (optPkgIf (cfg.nixos.enable && isLinux) "mcp-nixos")
      ++ (optionals (cfg.nixos.enable && isDarwin) [uv])

      # VERSION CONTROL
      ++ (optPkgIf cfg.github.enable "github-mcp-server")
      ++ (optPkgIf cfg.gitea.enable "gitea-mcp-server")

      # CLOUD & INFRASTRUCTURE
      ++ (optPkgIf cfg.kubernetes.enable "mcp-k8s-go")
      ++ (optPkgIf cfg.aks.enable "aks-mcp-server")
      ++ (optPkgIf cfg.grafana.enable "mcp-grafana")
      ++ (optPkgIf cfg.terraform.enable "terraform-mcp-server")
      ++ (optPkgIf cfg.fluxcd.enable "fluxcd-operator-mcp")

      # BROWSER AUTOMATION
      ++ (optPkgIf cfg.playwright.enable "playwright-mcp")

      # DEVELOPMENT TOOLS
      ++ (optPkgIf cfg.languageServer.enable "mcp-language-server")

      # MCP INFRASTRUCTURE & UTILITIES
      ++ (optPkgIf cfg.mcphost.enable "mcphost")
      ++ (optPkgIf cfg.toolhive.enable "toolhive")
      ++ (optPkgIf (cfg.proxy.enable && isLinux) "mcp-proxy")
      ++ (optPkgIf (cfg.chatmcp.enable && isLinux) "chatmcp")

      # PYTHON MCP ECOSYSTEM (Linux only)
      ++ (optionals (cfg.pythonSdk.enable && isLinux && builtins.hasAttr "mcp" python313Packages) [python313Packages.mcp])
      ++ (optionals (cfg.fastmcp.enable && isLinux && builtins.hasAttr "fastmcp" python313Packages) [python313Packages.fastmcp])
      ++ (optionals (cfg.mcpadapt.enable && isLinux && builtins.hasAttr "mcpadapt" python313Packages) [python313Packages.mcpadapt])
      ++ (optionals (cfg.docling.enable && isLinux && builtins.hasAttr "docling-mcp" python313Packages) [python313Packages.docling-mcp])
      ++ (optionals (cfg.fastapiMcp.enable && isLinux && builtins.hasAttr "fastapi-mcp" python313Packages) [python313Packages.fastapi-mcp])
      ++ (optionals (cfg.djangoMcp.enable && isLinux && builtins.hasAttr "django-mcp-server" python313Packages) [python313Packages.django-mcp-server])

      # HASKELL MCP ECOSYSTEM
      ++ (optionals (cfg.haskellMcp.enable && builtins.hasAttr "mcp" haskellPackages) [haskellPackages.mcp])
      ++ (optionals (cfg.haskellMcpServer.enable && builtins.hasAttr "mcp-server" haskellPackages) [haskellPackages.mcp-server])
      ++ (optionals (cfg.ptyMcpServer.enable && builtins.hasAttr "pty-mcp-server" haskellPackages) [haskellPackages.pty-mcp-server]);
  });
}
