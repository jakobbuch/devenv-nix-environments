{ inputs, ... }:
{
  # Import its own modules for development
  imports = [
    ./devenv/nix-dev.nix
    ./devenv/nix-hooks-dev.nix
    ./devenv/git-hooks-dev.nix
    ./devenv/markdown-dev.nix
    ./devenv/markdown-hooks-dev.nix
  ];

  # Additional repository-specific configuration
  packages = [ ];

  enterShell = ''
    echo "Devenv Template Repository Development Shell"
    echo "Nix and Git hooks modules loaded."
  '';
}
