# Security & Database Tools Package Set
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.blackmatter.components.packages.security;
in {
  options.blackmatter.components.packages.security = {
    enable = mkEnableOption "security and database tools package set";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Security tools
      nmap openssl gnupg hashcat
      # john  # TODO: Re-enable when GCC 14 compatibility is fixed - gpg2john.c has function pointer bugs

      # Password managers
      pass gopass bitwarden-cli

      # Database CLI tools
      postgresql mysql80 sqlite redis mongodb-tools

      # Crypto tools
      minisign
    ];
  };
}
