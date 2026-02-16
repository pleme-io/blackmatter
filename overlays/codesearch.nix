# Codesearch — semantic code search with BM25 + vector embeddings + tree-sitter AST
#
# Built from pleme-io fork (fixes MCP readonly mode to prevent hot loop).
# Uses fenix stable toolchain (rmcp requires rustc 1.88+).
# Called from parts/overlays.nix which passes {inputs} for fenix access.
#
# The `ort` crate uses `download-binaries` by default, which tries to fetch
# ONNX Runtime at build time — blocked by Nix sandbox. We set ORT_LIB_LOCATION
# to point at the pre-built nixpkgs onnxruntime instead.
{inputs}:
final: prev: let
  fenixPkgs = inputs.fenix.packages.${prev.system};
  rustToolchain = fenixPkgs.stable.withComponents ["rustc" "cargo"];
  rustPlatform = prev.makeRustPlatform {
    rustc = rustToolchain;
    cargo = rustToolchain;
  };

  # ort-sys 2.0.0-rc.11 requires ORT API version 23 (onnxruntime 1.23+).
  # nixpkgs already has 1.23.2, so use it directly.
  onnxruntime = prev.onnxruntime;
in {
  codesearch = rustPlatform.buildRustPackage rec {
    pname = "codesearch";
    version = "0.1.142";

    src = prev.fetchFromGitHub {
      owner = "pleme-io";
      repo = "codesearch";
      rev = "3345b85c90ba282bef6ece8dc247f575c030ee2b";
      hash = "sha256-pYHhrCAnPfMPGKLrzXWtYBPmpliaFjc0B7o8vXXkAaA=";
    };

    cargoHash = "sha256-QpzLdvDXp2HtVtK+W3UdCxzvUtN6GkjCxfRatXzKJlk=";

    nativeBuildInputs = with prev; [
      protobuf
      pkg-config
      cmake
    ];

    buildInputs = [
      prev.openssl
      onnxruntime
    ];

    # Tell the `ort` crate to use pre-built ONNX Runtime from nixpkgs
    # instead of downloading binaries at build time (blocked by Nix sandbox)
    ORT_LIB_LOCATION = "${onnxruntime}/lib";
    ORT_PREFER_DYNAMIC_LINK = "1";

    # The Nix sandbox unpacks source into $NIX_BUILD_TOP/source/ but cargo
    # writes to $NIX_BUILD_TOP/target/ — the install hook expects target/ to
    # be relative to pwd (source/). Fix by anchoring CARGO_TARGET_DIR.
    preBuild = ''
      export CARGO_TARGET_DIR="$(pwd)/target"
    '';

    # Ensure the ONNX Runtime dylib is found at runtime via rpath
    postFixup = ''
      install_name_tool -add_rpath "${onnxruntime}/lib" "$out/bin/codesearch"
    '';

    doCheck = false;
  };
}
