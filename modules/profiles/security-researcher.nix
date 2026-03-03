# modules/profiles/security-researcher.nix
#
# Stub — declares the security.plo.* option tree consumed by blizzard/security
# and cid-k3s. Accepts any definitions without enforcement — actual tool
# installation is handled by blackmatter-security when available.
{ lib, ... }: {
  options.security.plo = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {};
    description = "Security researcher tool configuration (stub — accepts any value).";
  };
}
