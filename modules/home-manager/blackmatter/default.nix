{lib, ...}:
with lib; {
  imports = [
    ./profiles
    ./components
    ./themes
  ];
  options = {
    blackmatter = {
      enable = mkEnableOption "enable blackmatter";
    };
  };

  # Tatara-script is pleme-io's canonical scripting language — replaces
  # bash in nix-run apps, fleet flows, and multi-step orchestration.
  # Enable by default on every node that imports the blackmatter HM
  # module; opt out explicitly via
  #   blackmatter.components.tatara-script.enable = false;
  # when (very rarely) a sub-user shouldn't have it.
  config = {
    blackmatter.components.tatara-script.enable = mkDefault true;
  };
}
