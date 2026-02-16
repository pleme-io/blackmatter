# modules/nixos/blackmatter/profiles/blizzard/networking/default.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.blizzard;
in {
  options = {
    blackmatter = {
      profiles = {
        blizzard = {
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
    # networking.networkmanager.enable = true;
    # networking.wireless.interfaces = ["wlp0s20f3"];
    # networking.firewall.enable = false;
    # networking.firewall.extraCommands = ''
    #   ip46tables -I INPUT 1 -i vboxnet+ -p tcp -m tcp --dport 2049 -j ACCEPT
    # '';
    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = mkDefault cfg.ssh.permitRootLogin;
    services.openssh.settings.PasswordAuthentication = mkDefault cfg.ssh.passwordAuthentication;
    services.dnsmasq.enable = true;
    services.dnsmasq.settings.server = [
      "1.1.1.1"
      "1.0.0.1"
      "8.8.8.8"
      "8.8.4.4"
    ];
  };
}
