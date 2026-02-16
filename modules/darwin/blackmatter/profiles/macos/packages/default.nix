# modules/darwin/blackmatter/profiles/macos/packages/default.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.macos.packages;

  # Platform detection using pkgs.stdenv
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Platform-specific compiler
  # On macOS, use clang (native)
  # On Linux, use gcc
  compiler =
    if isDarwin
    then pkgs.clang
    else pkgs.gcc;
in {
  options = {
    blackmatter = {
      profiles = {
        macos = {
          packages = {
            enable = mkEnableOption "enable package management configuration";

            allowUnfree = mkOption {
              type = types.bool;
              default = true;
              description = "Allow unfree packages";
            };

            allowUnfreeList = mkOption {
              type = types.listOf types.str;
              default = ["packer"];
              description = "List of specific unfree packages to allow";
            };

            permittedInsecurePackages = mkOption {
              type = types.listOf types.str;
              default = [
                "python2.7-pyjwt-1.7.1"
                "lima-1.0.7"  # Required by nix-rosetta-builder (CVEs in nerdctl dep, fixed in unstable)
              ];
              description = "List of insecure packages to permit";
            };

            systemPackages = mkOption {
              type = types.listOf types.package;
              default = with pkgs; [
                gh
                slack-cli
                cargo
                lua-language-server
                docker
                docker-client
                tfswitch
                ripgrep
                weechat
                gnumake
                openssh
                nix-index
                nodejs
                bundix
                zoxide
                arion
                unzip
                gnupg
                lorri
                htop
                wget
                nmap
                stow
                zlib
                curl
                compiler # Platform-specific: clang on macOS, gcc on Linux
                age
                git
                dig
                vim
                attic-client
              ];
              description = "System-wide packages to install";
            };

            userPackages = mkOption {
              type = types.listOf types.package;
              default = with pkgs;
                [
                  nerd-fonts.fira-code
                  home-manager
                  ffmpeg-full
                ]
                ++ (
                  if isDarwin
                  then [
                    libiconv # macOS-specific: needed for build tooling
                  ]
                  else []
                )
                ++ [
                  # tlaps - disabled: vampire-5.0.0 build failure in nixpkgs
                  # tlafmt - not available in nixpkgs 24.11
                  tlaplus
                  fluxcd
                  # poetry  # Disabled: rapidfuzz build failure (std::atomic) on aarch64-darwin
                  delta
                  bat
                  go
                ]
                ++
                # note taking
                [obsidian];
              description = "User-specific packages to install";
            };

            homeManagerUser = mkOption {
              type = types.str;
              default = "drzzln";
              description = "Username for home-manager package configuration";
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # Nixpkgs configuration
    nixpkgs.config = {
      allowUnfree = cfg.allowUnfree;
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) cfg.allowUnfreeList;
      permittedInsecurePackages = cfg.permittedInsecurePackages;
    };

    # Install system packages
    environment.systemPackages = cfg.systemPackages;

    # Install user packages via home-manager
    home-manager.users.${cfg.homeManagerUser} = {
      home.packages = cfg.userPackages;
    };
  };
}
