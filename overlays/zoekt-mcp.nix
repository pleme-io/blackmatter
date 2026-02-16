# zoekt-mcp — MCP server wrapping Zoekt search API for Claude Code
#
# Uses fenix stable toolchain (rmcp requires rustc 1.88+).
# Called from parts/overlays.nix which passes {inputs} for fenix access.
#
# Uses path literal relative to this file (../../ = repo root) so it works
# from both the root flake.nix and nix/flake.nix.
{inputs}: let
  zoektSrc = ../../pkgs/platform/zoekt-mcp;
in
  final: prev: let
    fenixPkgs = inputs.fenix.packages.${prev.system};
    rustToolchain = fenixPkgs.stable.withComponents ["rustc" "cargo"];
    rustPlatform = prev.makeRustPlatform {
      rustc = rustToolchain;
      cargo = rustToolchain;
    };
  in {
    zoekt-mcp = rustPlatform.buildRustPackage {
      pname = "zoekt-mcp";
      version = "0.1.0";
      src = zoektSrc;
      cargoLock.lockFile = zoektSrc + "/Cargo.lock";
    };
  }
