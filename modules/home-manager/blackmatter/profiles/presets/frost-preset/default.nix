# Frost Preset - Minimal developer profile using new modular system
{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.blackmatter.profiles.presets.frost-preset;
in {
  options.blackmatter.profiles.presets.frost-preset = {
    enable = mkEnableOption "Frost preset (minimal developer profile)";
  };

  config = mkIf cfg.enable {
    # Use base developer profile
    blackmatter.profiles.base.developer.enable = true;

    # Desktop component (minimal)
    blackmatter.components.desktop.kitty.enable = true;

    # Kubernetes tools
    blackmatter.components.kubernetes.enable = mkDefault true;

    # OpenCode AI coding agent
    blackmatter.components.opencode.enable = mkDefault true;
  };
}
