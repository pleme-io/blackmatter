# NixOS Blackmatter Components

## Overview
System-level components for the blackmatter framework, providing microservices, desktop environments, networking, and core system functionality.

## Component Categories

### Microservices
Self-hosted services and applications with standardized configuration patterns:
- Web applications (Gitea, Mastodon, Matrix)
- Infrastructure services (Traefik, HAProxy, Consul)
- Databases (PostgreSQL, ProxySQL)
- Development tools (Keycloak, Minio)

### Desktop
System-level desktop environment configurations:
- Display managers
- Window manager support
- GPU drivers and acceleration
- Audio subsystems

### Networking
- WireGuard VPN configurations
- Site-to-site networking
- Network security policies

### Kubernetes
- K3s lightweight Kubernetes
- Container orchestration
- Service mesh integration

## Architecture Principles

### Standardization
All microservices follow common patterns:
- Consistent option naming
- Shared base configurations
- Unified SSL/TLS handling
- Standard database patterns

### Validation
Enhanced validation system provides:
- Port conflict detection
- Configuration consistency checks
- Security warnings
- Clear error messages

### Flexibility
- Development and production modes
- Modular enabling/disabling
- Override capabilities
- Custom configurations

## Usage Patterns

### Enable a Microservice
```nix
{
  blackmatter.components.microservices.gitea = {
    enable = true;
    domain = "git.example.com";
    port = 3000;
  };
}
```

### Development Mode
```nix
{
  blackmatter.components.microservices.traefik = {
    enable = true;
    mode = "dev";  # Uses localhost, self-signed certs
  };
}
```

### Production Configuration
```nix
{
  blackmatter.components.microservices.traefik = {
    enable = true;
    mode = "prod";
    acmeEmail = "admin@yourdomain.com";
    domain = "proxy.yourdomain.com";
  };
}
```

## Common Options

Most microservices support:
- `enable` - Activate the service
- `port` - Main service port
- `dataDir` - Data storage location
- `mode` - "dev" or "prod"
- `domain` - Service domain (prod mode)
- `ssl` - SSL/TLS configuration
- `database` - Database backend settings

## Integration Points

### With Profiles
System profiles automatically configure multiple components:
```nix
blackmatter.profiles.blizzard.enable = true;
# Enables desktop, networking, and common services
```

### With Home-Manager
System components complement user-level configurations:
- System provides services
- Home-manager configures clients
- Shared theming and standards

### With Secrets
SOPS-based secret management for:
- Database passwords
- API tokens
- SSL certificates
- Service credentials

## Best Practices

### Security
- Use production mode for internet-facing services
- Enable SSL for all external services
- Configure firewalls appropriately
- Regular secret rotation

### Performance
- Monitor resource usage
- Configure appropriate limits
- Use caching where available
- Enable compression

### Maintenance
- Regular backups of data directories
- Monitor service logs
- Keep dependencies updated
- Test configuration changes

## Troubleshooting

### Service Won't Start
```bash
systemctl status service-name
journalctl -u service-name -f
```

### Port Conflicts
The validation system will catch these at build time.
Check which service uses a port:
```bash
sudo lsof -i :PORT
```

### Permission Issues
Ensure service users own their data directories:
```bash
ls -la /var/lib/service-name
```

## Related Documentation
- Individual component READMEs in subdirectories
- `/modules/nixos/blackmatter/lib/` - Shared libraries
- `/modules/nixos/blackmatter/profiles/` - System profiles