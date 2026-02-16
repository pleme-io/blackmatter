# Base overlay utilities and patterns
{ lib }:
rec {
  # Create an overlay from a package set
  mkPackageOverlay = packages: final: prev:
    lib.mapAttrs (name: pkg: 
      if builtins.isFunction pkg then
        pkg final prev
      else
        pkg
    ) packages;
  
  # Create an overlay that modifies existing packages
  mkModificationOverlay = modifications: final: prev:
    lib.mapAttrs (name: mod:
      if prev ? ${name} then
        prev.${name}.overrideAttrs mod
      else
        throw "Package ${name} not found in nixpkgs"
    ) modifications;
  
  # Create an overlay with version pinning
  mkVersionOverlay = versions: final: prev:
    lib.mapAttrs (name: version:
      if prev ? ${name} then
        prev.${name}.overrideAttrs (old: {
          inherit version;
          src = if versions.${name} ? src then
            versions.${name}.src
          else
            old.src;
        })
      else
        throw "Package ${name} not found for version override"
    ) versions;
  
  # Compose multiple overlays
  composeOverlays = overlays: final: prev:
    builtins.foldl' (acc: overlay:
      acc // overlay final (prev // acc)
    ) {} overlays;
  
  # Create conditional overlay
  mkConditionalOverlay = condition: overlay: final: prev:
    if condition then overlay final prev else {};
  
  # Platform-specific overlay
  mkPlatformOverlay = { linux ? {}, darwin ? {}, ... }: final: prev:
    let
      platformOverlay = 
        if prev.stdenv.isLinux then linux
        else if prev.stdenv.isDarwin then darwin
        else {};
    in mkPackageOverlay platformOverlay final prev;
  
  # Architecture-specific overlay
  mkArchOverlay = { x86_64 ? {}, aarch64 ? {}, ... }: final: prev:
    let
      archOverlay =
        if prev.stdenv.hostPlatform.isAarch64 then aarch64
        else if prev.stdenv.hostPlatform.isx86_64 then x86_64
        else {};
    in mkPackageOverlay archOverlay final prev;
  
  # Development overlay (adds development tools)
  mkDevOverlay = devPackages: final: prev:
    let
      devTools = lib.mapAttrs (name: pkg:
        if prev ? ${name} then
          prev.${name}.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ (pkg.buildInputs or []);
            buildInputs = (old.buildInputs or []) ++ (pkg.runtimeInputs or []);
          })
        else
          pkg
      ) devPackages;
    in mkPackageOverlay devTools final prev;
  
  # Patch overlay (applies patches to packages)
  mkPatchOverlay = patches: final: prev:
    lib.mapAttrs (name: patchList:
      if prev ? ${name} then
        prev.${name}.overrideAttrs (old: {
          patches = (old.patches or []) ++ patchList;
        })
      else
        throw "Package ${name} not found for patching"
    ) patches;
  
  # Environment overlay (sets environment variables)
  mkEnvOverlay = envVars: final: prev:
    lib.mapAttrs (name: vars:
      if prev ? ${name} then
        prev.${name}.overrideAttrs (old: {
          inherit (vars) env;
        })
      else
        throw "Package ${name} not found for environment override"
    ) envVars;
  
  # Build flag overlay
  mkFlagOverlay = flags: final: prev:
    lib.mapAttrs (name: pkgFlags:
      if prev ? ${name} then
        prev.${name}.override pkgFlags
      else
        throw "Package ${name} not found for flag override"
    ) flags;
  
  # Unfree overlay (allows unfree packages)
  mkUnfreeOverlay = packages: final: prev:
    let
      config = {
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) packages;
      };
    in {
      inherit config;
    };
  
  # Insecure overlay (allows insecure packages)
  mkInsecureOverlay = packages: final: prev:
    let
      config = {
        permittedInsecurePackages = packages;
      };
    in {
      inherit config;
    };
  
  # Priority overlay (sets package priorities)
  mkPriorityOverlay = priorities: final: prev:
    lib.mapAttrs (name: priority:
      if prev ? ${name} then
        lib.setPrio priority prev.${name}
      else
        throw "Package ${name} not found for priority override"
    ) priorities;
  
  # Wrapper overlay (creates wrapped versions)
  mkWrapperOverlay = wrappers: final: prev:
    lib.mapAttrs (name: wrapper:
      let
        original = prev.${name} or (throw "Package ${name} not found for wrapping");
      in prev.symlinkJoin {
        name = "${name}-wrapped";
        paths = [ original ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = wrapper.postBuild or ''
          wrapProgram $out/bin/${wrapper.binary or name} \
            ${lib.optionalString (wrapper ? env) 
              (lib.concatStringsSep " " (lib.mapAttrsToList (k: v: 
                "--set ${k} ${v}"
              ) wrapper.env))} \
            ${lib.optionalString (wrapper ? prefix)
              "--prefix PATH : ${lib.makeBinPath wrapper.prefix}"} \
            ${wrapper.extraArgs or ""}
        '';
      }
    ) wrappers;
}