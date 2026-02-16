# Development Components Collection
{ ... }: {
  imports = [
    ./cli-editors.nix
    ./git-tools.nix        # Round 4
    # Future development modules will be added here:
    # ./modern-cli.nix     # Round 8
  ];
}