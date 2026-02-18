# Attic Binary Cache Configuration
# Single source of truth for Attic cache settings
{
  # Attic cache JWT token — stored in nix/secrets.yaml under attic/token
  # Retrieve via: sops -d nix/secrets.yaml | jq -r '.attic.token'
  # Do NOT hardcode tokens here — they expire and must be rotated
  token = builtins.getEnv "ATTIC_TOKEN";

  # Cache configuration - new shared nix-cache namespace
  cache = {
    url = "http://cache.plo.quero.local/nexus";  # Full URL with cache name for Nix substituters
    hostname = "cache.plo.quero.local";
    cacheName = "nexus";  # The cache name within Attic

    # All public keys that might be used to sign cache items
    # Multiple keys exist due to key rotation or multiple cache instances
    publicKeys = [
      "nexus:gKq7WG+yOzdGFq4VhHbEvlS3kwz3Q8gawHNqoybfv9Y="   # New nexus cache key
      "novaskyn:fSfAOosYuhryRFJkPrcChWuz/eqiGRRutQ81v8uvkPY="  # Legacy key 1
      "novaskyn:liS6oN1DvhDmYierLxr/evFvwKbShfwn3gcIzMO5U7c="  # Legacy key 2
      "novaskyn:nWdTJTAkWBDfUrnM6iTHn7uh8kw7IgT0xAFIuUVRANU="  # Legacy key 3
    ];

    # Primary public key (current)
    publicKey = "nexus:gKq7WG+yOzdGFq4VhHbEvlS3kwz3Q8gawHNqoybfv9Y=";
  };
}
