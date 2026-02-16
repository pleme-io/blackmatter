# Validation System Guide

## Overview
The blackmatter validation system provides comprehensive configuration validation with clear error messages and helpful warnings. It catches common mistakes at build time rather than runtime.

## Core Features

### Automatic Validation
When using enhanced base patterns, validation is automatic:
```nix
# This automatically includes validation
options.blackmatter.components.microservices.myservice = {
  port = base.types.validatedPort "myservice" // { default = 8080; };
};
```

### Cross-Service Validation
The system detects conflicts between services:
- Port conflicts between services
- Data directory overlaps
- Resource contention

### Configuration Consistency
Ensures related options are consistent:
- Database type matches password requirements
- SSL configuration has necessary files
- Production mode has proper settings

## Using Enhanced Types

### Validated Port
```nix
port = base.types.validatedPort "serviceName" // { default = 8080; };
```
Validates:
- Port is in valid range (1024-65535 for non-privileged)
- Port is unique across all services
- Special handling for 80/443

### Validated Domain
```nix
domain = base.types.validatedDomain "serviceName" // { 
  default = "service.example.com"; 
};
```
Validates:
- Proper domain format
- Contains at least one dot
- Valid characters only

### Validated Data Directory
```nix
dataDir = base.types.validatedDataDir "serviceName" "/var/lib/service";
```
Validates:
- Path is absolute
- No conflicts with other services
- Proper permissions possible

### Validated Database
```nix
database = base.types.validatedDatabase // {
  type = mkOption {
    default = "postgres";
  };
};
```
Validates:
- Password required for mysql/postgres
- Connection settings consistency
- Security warnings for remote connections

## Custom Validation

### Adding Service-Specific Validation
```nix
config = mkIf cfg.enable {
  assertions = [
    {
      assertion = cfg.specialOption > 0 && cfg.specialOption < 100;
      message = "Service ${name} specialOption must be between 1-99";
    }
    {
      assertion = !(cfg.mode == "prod" && cfg.debugEnabled);
      message = "Debug mode should not be enabled in production";
    }
  ];
};
```

### Adding Warnings
```nix
warnings = [
  (mkIf (cfg.mode == "dev" && cfg.publicAccess) 
    "Service ${name} has public access in dev mode - security risk")
  (mkIf (cfg.database.type == "sqlite3" && cfg.highTraffic)
    "SQLite may not handle high traffic well - consider PostgreSQL")
];
```

## Validation Messages

### Good Error Messages
```nix
assertion = cfg.port >= 1024;
message = "Service '${name}' port ${toString cfg.port} must be >= 1024 (use systemd socket activation for privileged ports)";
```
- Names the service
- Shows the invalid value
- Explains the requirement
- Suggests a solution

### Good Warning Messages
```nix
warning = "Service '${name}' using default password - change before production deployment";
```
- Identifies the issue
- Explains the risk
- Provides action item

## Common Validations

### Mode-Specific Validation
```nix
assertion = !(cfg.mode == "prod" && cfg.ssl.enable == false);
message = "Production mode requires SSL to be enabled";
```

### Dependency Validation
```nix
assertion = cfg.database.enable -> config.services.postgresql.enable;
message = "Service requires PostgreSQL to be enabled";
```

### Resource Validation
```nix
assertion = cfg.memoryLimit >= cfg.memoryRequest;
message = "Memory limit must be >= memory request";
```

## Integration with Base Patterns

### Using mkMicroservice
```nix
base.patterns.mkMicroservice {
  name = "myservice";
  options = {
    # These automatically get validation
    port = base.types.validatedPort "myservice";
    domain = base.types.validatedDomain "myservice";
  };
  config = {
    # Additional service config
  };
}
```

### Manual Integration
```nix
let
  validation = import ../../../lib/validation.nix { inherit lib config; };
  assertions = validation.mkMicroserviceAssertions "myservice" cfg;
in {
  config = mkIf cfg.enable {
    inherit assertions;
  };
}
```

## Testing Validation

### Trigger Validation Errors
```nix
# Test port conflict
service1.port = 8080;
service2.port = 8080;  # Should error

# Test invalid domain
service.domain = "not-a-domain";  # Should error

# Test missing password
database.type = "postgres";
database.passwordFile = null;  # Should error
```

### Check Warnings
```bash
# Build with warnings visible
nix build --show-trace .#nixosConfigurations.hostname.config.warnings

# Or during rebuild
sudo nixos-rebuild switch --show-trace
```

## Best Practices

### Be Specific
Instead of:
```nix
assertion = cfg.value != null;
message = "Value required";
```

Use:
```nix
assertion = cfg.apiKey != null;
message = "Service '${name}' requires apiKey to be set for authentication";
```

### Validate Early
Put validations in the module where the option is defined, not where it's used.

### Group Related Validations
```nix
assertions = [
  # SSL validations
  sslAssertion1
  sslAssertion2
  # Database validations  
  dbAssertion1
  dbAssertion2
];
```

### Consider User Experience
- Validate at build time, not runtime
- Provide helpful error messages
- Suggest fixes where possible
- Warn about insecure defaults

## Extending Validation

### Add New Validators
In `lib/validation.nix`:
```nix
validators.validateNewThing = value: name: {
  assertion = /* validation logic */;
  message = /* error message */;
};
```

### Add New Enhanced Types
```nix
enhancedTypes.validatedNewType = mkOption {
  type = types.addCheck types.str (x: /* validation */ );
  description = "Description with validation rules";
};
```

## Troubleshooting

### Validation Not Running
- Ensure service is enabled
- Check that enhanced types are used
- Verify base patterns are imported

### Too Many False Positives
- Make validations more specific
- Add conditional logic
- Consider warnings instead of errors

### Performance Impact
- Validations run at evaluation time
- Keep validation logic simple
- Avoid expensive operations

## Related Documentation
- `lib/validation.nix` - Core validation implementation
- `lib/README.md` - Validation library docs
- Individual service documentation