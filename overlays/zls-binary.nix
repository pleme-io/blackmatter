# ZLS pre-built binary overlay
# The nixpkgs ZLS derivation fails in the Nix sandbox with:
#   ln: failed to create symbolic link '/p': Read-only file system
# Use the official pre-built binary from GitHub releases instead.
final: prev: {
  zls = prev.stdenv.mkDerivation rec {
    pname = "zls";
    version = "0.15.1";

    src = prev.fetchurl {
      url = "https://github.com/zigtools/zls/releases/download/${version}/zls-aarch64-macos.tar.xz";
      hash = "sha256-prPxsQ138387nZYgk/AwM0sIP0jrJgeks8y3LeKVgTM=";
    };

    sourceRoot = ".";

    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      install -Dm755 zls $out/bin/zls
    '';

    meta = with prev.lib; {
      description = "Zig Language Server";
      homepage = "https://github.com/zigtools/zls";
      license = licenses.mit;
      platforms = [ "aarch64-darwin" ];
    };
  };
}
