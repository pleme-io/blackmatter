# NixOS-specific cross-platform compatibility
{ lib, config, pkgs, ... }:
let
  baseCrossPlatform = import ../../../blackmatter/lib/cross-platform.nix {
    inherit lib config pkgs;
  };
in {
  imports = [ baseCrossPlatform ];
  
  # NixOS-specific overrides and additions
  config = lib.mkIf config.blackmatter.crossPlatform.enable {
    # Ensure we're on Linux
    assertions = [{
      assertion = pkgs.stdenv.isLinux;
      message = "NixOS cross-platform module should only be used on Linux";
    }];
    
    # Linux-specific service configuration
    systemd = lib.mkIf (config.blackmatter.crossPlatform.services.type == "systemd") {
      # Enable user services
      user.enable = true;
    };
    
    # X11/Wayland configuration
    services = lib.mkIf config.blackmatter.crossPlatform.desktop.available {
      xserver = lib.mkIf (config.blackmatter.crossPlatform.desktop.displayServer == "x11") {
        enable = lib.mkDefault true;
      };
    };
  };
}