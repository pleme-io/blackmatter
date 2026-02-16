# Library Documentation

## Overview

This directory contains shared Nix library functions and utilities used throughout the configuration.

## Contents

### flake-inputs.nix

Comprehensive flake input management library providing:

- **Input categorization**: Organize inputs by purpose (core, userEnvironment, desktop, security)
- **Update strategies**: Conservative, regular, and aggressive update patterns
- **Health checks**: Validate input consistency and staleness
- **Dependency tracking**: Track which inputs follow others
- **Pin management**: Pin/unpin inputs to specific versions
- **Reporting**: Generate status and update reports

#### Key Functions

- `categories`: Input groupings by purpose
- `inputMetadata`: Metadata about each input (update frequency, criticality)
- `shouldUpdate`: Determine if an input needs updating based on age and frequency
- `updateStrategies`: Different approaches to updating inputs
- `checks`: Health and consistency validation
- `pins`: Pin management utilities
- `reports`: Generate various reports about input status

#### Usage Example

```nix
let
  lib = pkgs.lib;
  flakeInputs = import ./lib/flake-inputs.nix { inherit lib; };
  
  # Check if nixpkgs should be updated
  shouldUpdate = flakeInputs.shouldUpdate "nixpkgs" lastModified currentTime;
  
  # Get all core inputs
  coreInputs = flakeInputs.categories.core;
  
  # Generate update report
  report = flakeInputs.reports.updateReport lockFile currentTime;
in
  # Use the utilities
```

## Integration with Scripts

The library is used by:
- `bin/flake-update`: Command-line tool for managing flake inputs
- `bin/update`: Simple update wrapper (calls flake-update)

## Adding New Libraries

When adding new library files:

1. Create the file in this directory
2. Follow the pattern of accepting `{ lib }` as an argument
3. Return an attribute set of functions
4. Document the library here
5. Import and use in relevant modules or scripts

## Best Practices

1. **Pure Functions**: Keep functions pure when possible
2. **Clear Naming**: Use descriptive function names
3. **Documentation**: Add comments explaining complex logic
4. **Testing**: Test functions with `nix repl` or evaluation
5. **Composability**: Design functions to work together

## Testing Library Functions

Test in nix repl:
```bash
$ nix repl
nix-repl> lib = (import <nixpkgs> {}).lib
nix-repl> flakeInputs = import ./lib/flake-inputs.nix { inherit lib; }
nix-repl> flakeInputs.categories.core
[ "nixpkgs" "flake-parts" "flake-utils" ]
```

Or with nix-instantiate:
```bash
nix-instantiate --eval -E '
  let
    lib = (import <nixpkgs> {}).lib;
    flakeInputs = import ./lib/flake-inputs.nix { inherit lib; };
  in
    flakeInputs.shouldUpdate "nixpkgs" 1234567890 1234567900
'
```