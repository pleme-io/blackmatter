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
}
