# Fix poetry pbs-installer version conflict
# poetry requires pbs-installer<2026.0.0,>=2025.1.6
# nixpkgs has pbs-installer 2026.1.13 which doesn't satisfy the constraint
# Solution: override poetry to skip pbs-installer runtime dependency check
final: prev: {
  # Override top-level poetry package
  poetry = prev.poetry.overridePythonAttrs (old: {
    dontCheckRuntimeDeps = true;
  });
}
