# GCC 15 compatibility fixes
# GCC 15 enforces stricter C standards - these packages need relaxed warnings
final: prev: let
  # Helper to add relaxed pointer type warnings for C code
  relaxCPointerTypes = pkg: pkg.overrideAttrs (old:
    let
      existingFlags = if old ? env && old.env ? NIX_CFLAGS_COMPILE
                      then old.env.NIX_CFLAGS_COMPILE
                      else (old.NIX_CFLAGS_COMPILE or "");
      newFlags = toString existingFlags + " -Wno-error=incompatible-pointer-types -Wno-error=int-conversion";
    in {
      env = (old.env or {}) // { NIX_CFLAGS_COMPILE = newFlags; };
    }
  );

  # Helper for packages that need all C implicit function errors disabled
  relaxCImplicit = pkg: pkg.overrideAttrs (old:
    let
      existingFlags = if old ? env && old.env ? NIX_CFLAGS_COMPILE
                      then old.env.NIX_CFLAGS_COMPILE
                      else (old.NIX_CFLAGS_COMPILE or "");
      newFlags = toString existingFlags + " -Wno-error";
    in {
      env = (old.env or {}) // { NIX_CFLAGS_COMPILE = newFlags; };
      hardeningDisable = (old.hardeningDisable or []) ++ [ "format" "fortify" ];
    }
  );
in {
  # Medusa - libssh2 callback type mismatches
  medusa = relaxCPointerTypes prev.medusa;
}
