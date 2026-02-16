# modules/nixos/blackmatter/profiles/nordstorm/nix/default.nix
# Nix settings now managed by shared/nix-performance.nix module
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.nordstorm;
in {
  config = mkIf cfg.enable {
    # GNOME doesn't need Hyprland cachix, so we don't add extra substituters
  };
}
