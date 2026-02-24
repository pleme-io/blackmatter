# Attic Binary Cache Configuration
# Returns a configuration attrset. Override values per-deployment.
{
  cacheUrl ? "http://localhost/cache",
  cacheHostname ? "localhost",
  cacheName ? "default",
  publicKeys ? [],
  publicKey ? "",
}:
{
  # Attic cache JWT token — sourced from environment
  token = builtins.getEnv "ATTIC_TOKEN";

  # Cache configuration
  cache = {
    url = cacheUrl;
    hostname = cacheHostname;
    cacheName = cacheName;
    publicKeys = publicKeys;
    publicKey = publicKey;
  };
}
