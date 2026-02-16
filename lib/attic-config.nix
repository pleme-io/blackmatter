# Attic Binary Cache Configuration
# Single source of truth for Attic cache settings
{
  # Attic cache JWT token (expires 2027-01-02)
  # Subject: nexus-ci
  # Permissions: read, write, create cache, create route on all caches
  token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3OTg5MjMwMjIsIm5iZiI6MTc2NzM2NTQyMiwic3ViIjoibmV4dXMtY2kiLCJodHRwczovL2p3dC5hdHRpYy5ycy92MSI6eyJjYWNoZXMiOnsiKiI6eyJyIjoxLCJ3IjoxLCJjYyI6MSwiY3IiOjF9fX19._pnRSRamWjGijv16yLSqeganhsM73XsKWpX-84xB4mw";

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
