# Shell Plugin Helper - Modular shell enhancement management
# Similar to plugin-helper.nix for neovim, but for shell plugins
{
  lib,
  pkgs,
  ...
}:
with lib; let
  # Common configuration home for shell plugins
  common = {
    configHome = ". ~/.config/shell/plugins";
  };

  # Convert Nix value to shell-compatible format (for env vars, arrays, etc.)
  toShellValue = lib.fix (self: val:
    if builtins.isString val
    then ''"${val}"''
    else if builtins.isBool val
    then (if val then "true" else "false")
    else if builtins.isInt val
    then toString val
    else if builtins.isList val
    then let
      items = map self val;
      joined = concatStringsSep " " items;
    in "(${joined})"
    else if builtins.isAttrs val
    then let
      pairs = lib.mapAttrsToList (k: v: "${k}=${self v}") val;
      joined = concatStringsSep "\n" pairs;
    in joined
    else throw "Unsupported shell value type: ${builtins.typeOf val}");

  # Generate Nix module for a shell plugin
  # Takes a plugin declaration and generates options + config
  mkPlugin = pluginDecl: let
    author = pluginDecl.author;
    name = pluginDecl.name;
    configDir = pluginDecl.configDir or null;
    priority = pluginDecl.load.priority or 50;

    # Replace dots with dashes for Nix option names
    nameWithDashes = lib.replaceStrings ["."] ["-"] name;

    # Path where config will be symlinked
    configPath =
      if configDir != null
      then "${common.configHome}/${author}/${nameWithDashes}"
      else null;
  in {
    lib,
    pkgs,
    config,
    ...
  }:
    with lib; {
      options.blackmatter.components.shell.plugins.${author}.${nameWithDashes} = {
        enable = mkEnableOption "enable ${author}/${name}";
        priority = mkOption {
          type = types.int;
          default = priority;
          description = "Loading priority (lower = earlier)";
        };
        defer = mkOption {
          type = types.bool;
          default = pluginDecl.load.defer or false;
          description = "Defer loading until after first prompt";
        };
      };

      config = mkIf config.blackmatter.components.shell.plugins.${author}.${nameWithDashes}.enable (mkMerge [
        # Symlink config directory if it exists
        (mkIf (configDir != null) {
          xdg.configFile."shell/plugins/${author}/${nameWithDashes}" = {
            source = configDir;
            recursive = true;
          };
        })

        # Install package from nixpkgs if source type is nixpkgs
        (mkIf (pluginDecl.source.type or null == "nixpkgs") {
          home.packages = [
            (getAttrFromPath (lib.splitString "." pluginDecl.source.package) pkgs)
          ];
        })

        # Fetch from GitHub if source type is github
        (mkIf (pluginDecl.source.type or null == "github") {
          home.file.".local/share/shell/plugins/${author}/${name}" = {
            source = builtins.fetchGit {
              url = "https://github.com/${pluginDecl.source.repo}";
              ref = pluginDecl.source.ref or "main";
              rev = pluginDecl.source.rev;
            };
            recursive = true;
          };
        })
      ]);
    };

  # Generate source command for a single plugin
  mkPluginSource = decl: let
    author = decl.author;
    name = decl.name;
    nameWithDashes = lib.replaceStrings ["."] ["-"] name;
    initFile = decl.load.initFile or "init.zsh";
  in ''
    # ${author}/${name}
    [[ -f ~/.config/shell/plugins/${author}/${nameWithDashes}/${initFile} ]] && \
      source ~/.config/shell/plugins/${author}/${nameWithDashes}/${initFile}
  '';

  # Generate shell initialization code for enabled plugins
  # Partitions into immediate and deferred (post-first-prompt) loading
  mkPluginInits = pluginDecls: config: let
    # Filter to only enabled plugins
    enabledPlugins = lib.filter (decl:
      config.blackmatter.components.shell.plugins.${decl.author}.${lib.replaceStrings ["."] ["-"] decl.name}.enable or false
    ) pluginDecls;

    # Sort by priority (lower number = load earlier)
    sortedPlugins = lib.sort (a: b:
      (a.load.priority or 50) < (b.load.priority or 50)
    ) enabledPlugins;

    # Partition into immediate vs deferred
    immediatePlugins = lib.filter (decl: !(decl.load.defer or false)) sortedPlugins;
    deferredPlugins = lib.filter (decl: decl.load.defer or false) sortedPlugins;

    # Generate init commands for immediate plugins
    immediateInits = map mkPluginSource immediatePlugins;

    # Generate deferred loading block (fires once after first prompt)
    deferredBlock =
      if deferredPlugins == []
      then ""
      else let
        deferredInits = map mkPluginSource deferredPlugins;
      in ''

        # ===== DEFERRED PLUGINS (loaded after first prompt) =====
        __blackmatter_deferred() {
          add-zsh-hook -d precmd __blackmatter_deferred
          unfunction __blackmatter_deferred
        ${lib.concatStringsSep "" deferredInits}
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook precmd __blackmatter_deferred
      '';
  in
    (lib.concatStringsSep "\n" immediateInits) + deferredBlock;

  # Generate .zshrc with plugin loading
  mkZshrc = pluginDecls: config: let
    pluginInits = mkPluginInits pluginDecls config;
  in ''
    # ~/.zshrc - Generated by Nix (blackmatter shell component)
    # DO NOT EDIT - Changes will be overwritten

    # Load core shell settings
    [[ -f ~/.config/shell/groups/common/settings.zsh ]] && \
      source ~/.config/shell/groups/common/settings.zsh

    # Initialize plugins (sorted by priority)
    ${pluginInits}

    # Load shell groups
    for group in ~/.config/shell/groups/*/init.zsh; do
      [[ -f "$group" ]] && source "$group"
    done
  '';
in {
  inherit
    toShellValue
    mkPlugin
    mkPluginInits
    mkZshrc
    ;
}
