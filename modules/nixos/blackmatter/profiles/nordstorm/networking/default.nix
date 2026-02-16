# modules/nixos/blackmatter/profiles/nordstorm/networking/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  options = {
    blackmatter = {
      profiles = {
        nordstorm = {
          ssh = {
            permitRootLogin = mkOption {
              type = types.str;
              default = "yes";
              description = "Whether root can login via SSH";
              example = "prohibit-password";
            };

            passwordAuthentication = mkOption {
              type = types.bool;
              default = true;
              description = "Whether to allow password authentication";
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # GNOME enables NetworkManager by default, which handles DNS
    # Don't enable system dnsmasq as it conflicts with NetworkManager's internal dnsmasq
    # networking.networkmanager.enable = true;  # Automatically enabled by GNOME
    # networking.wireless.interfaces = ["wlp0s20f3"];
    # networking.firewall.enable = false;
    # networking.firewall.extraCommands = ''
    #   ip46tables -I INPUT 1 -i vboxnet+ -p tcp -m tcp --dport 2049 -j ACCEPT
    # '';

    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = cfg.ssh.permitRootLogin;
    services.openssh.settings.PasswordAuthentication = cfg.ssh.passwordAuthentication;

    # Don't enable system dnsmasq - GNOME/NetworkManager handles DNS
    # For custom DNS servers, configure via NetworkManager instead
    # services.dnsmasq.enable = false;  # Explicitly disabled to avoid conflicts
  };
}
