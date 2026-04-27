{ pkgs, ... }:
{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    # pre-commit for git hooks management
    pre-commit
  ];

  # https://devenv.sh/scripts/
  scripts = {
    # Manual hook installation script
    installLocalHooks = {
      exec = ''
        if [ ! -d .git ]; then
          echo "Error: Not a git repository. Initialize git first."
          exit 1
        fi

        # Check if pre-commit config exists
        if [ ! -f .pre-commit-config.yaml ] && [ ! -f .pre-commit-config.yml ]; then
          echo "Error: No .pre-commit-config.yaml or .pre-commit-config.yml found."
          echo "Please create a pre-commit configuration file first."
          exit 1
        fi

        echo "Installing local git hooks via pre-commit..."

        if command -v uv &> /dev/null; then
          if uv run pre-commit --version &> /dev/null 2>&1; then
            uv run pre-commit install --install-hooks
            echo "Git hooks installed successfully via uv!"
          else
            echo "Warning: pre-commit not available via uv."
            echo "Run 'uv sync' to install dependencies first, then try again."
            exit 1
          fi
        elif command -v pre-commit &> /dev/null; then
          pre-commit install --install-hooks
          echo "Git hooks installed successfully via global pre-commit!"
        else
          echo "Error: pre-commit not found."
          echo "Please ensure uv is configured and dependencies are synced."
          exit 1
        fi
      '';
      description = "Install local git hooks via pre-commit (with safety checks)";
    };
  };

  # https://devenv.sh/reference/options/#entershell
  enterShell = ''
    # Auto-install git hooks if in a git repository
    if [ -d .git ]; then
      echo "Checking git hooks..."

      # Only attempt installation if pre-commit config exists
      if [ -f .pre-commit-config.yaml ] || [ -f .pre-commit-config.yml ]; then
        if command -v uv &> /dev/null; then
          if uv run pre-commit --version &> /dev/null 2>&1; then
            uv run pre-commit install --install-hooks 2>/dev/null || true
          fi
        elif command -v pre-commit &> /dev/null; then
          pre-commit install --install-hooks 2>/dev/null || true
        fi
      fi
    fi
  '';
}
