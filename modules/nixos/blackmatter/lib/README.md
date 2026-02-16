# Blackmatter Library Directory

This directory contains shared utility functions and patterns used across the blackmatter module system.

## Files

### validation.nix
Enhanced validation system for microservices and components.

**Features:**
- Port range validation (1024-65535 for non-privileged)
- Port uniqueness checking across services
- Domain name format validation
- Path validation for certificates and directories  
- Database configuration consistency checks
- SSL configuration validation
- Data directory conflict prevention

**Enhanced Option Types:**
```nix
types = {
  validatedPort = serviceName: mkOption { 
    type = types.port; 
    # Validates range and uniqueness
  };
  
  validatedDomain = serviceName: mkOption {
    type = types.str;
    # Validates domain format
  };
  
  validatedDatabase = mkOption {
    type = types.submodule;
    # Validates consistency (e.g., mysql needs password)
  };
}
```

**Usage Example:**
```nix
# In a microservice module
let
  base = import ../lib/base.nix { inherit lib config pkgs; };
in {
  options.myservice = {
    port = base.types.validatedPort "myservice" // { default = 8080; };
    dataDir = base.types.validatedDataDir "myservice" "/var/lib/myservice";
    domain = base.types.validatedDomain "myservice" // { default = "service.example.com"; };
  };
}
```

**Validation Warnings:**
- Development mode with production-like domains
- Default example domains in production
- Unencrypted database connections to remote hosts
- Disabled SSL in production mode

### secrets.nix
SOPS-based secrets management patterns.

**Features:**
- Centralized secret creation patterns
- Validation for secret configurations  
- Service-specific secret helpers
- Rotation and backup patterns

## Design Principles

1. **Fail Fast**: Validation errors appear at evaluation time
2. **Clear Messages**: Error messages explain what's wrong and how to fix it  
3. **Backward Compatible**: Legacy option types still work
4. **Composable**: Validation functions can be combined
5. **Service-Aware**: Cross-service validation (e.g., port conflicts)

## Integration

The validation system integrates automatically when using enhanced base patterns:

```nix
# microservices/lib/base.nix imports validation
let
  validation = import ../../../lib/validation.nix { inherit lib config; };
in {
  types = {
    # Enhanced types with validation
    validatedPort = serviceName: validation.enhancedTypes.validatedPort serviceName;
    # Legacy types for compatibility  
    port = mkOption { type = types.port; };
  };
}
```

Services using `base.patterns.mkMicroservice` automatically get validation.