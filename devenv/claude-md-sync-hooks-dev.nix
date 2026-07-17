{ pkgs, lib, ... }:
let
  # Create a wrapper script that finds the repo root and runs sync-claude-md.sh
  syncHook = pkgs.writeShellScriptBin "claude-md-sync-hook" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Find repo root (where .git is)
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

    # Run the sync script
    exec "$REPO_ROOT/scripts/sync-claude-md.sh" "$REPO_ROOT"
  '';
in
{
  # https://devenv.sh/git-hooks/
  git-hooks = {
    hooks = {
      # Custom hook to sync CLAUDE.md to AGENTS.md
      claude-md-sync = {
        enable = true;
        entry = "${syncHook}/bin/claude-md-sync-hook";
        language = "system";
        description = "Sync CLAUDE.md files to AGENTS.md";
        stages = [ "pre-commit" ];
        pass_filenames = false;
      };
    };
  };

  # Run sync when entering the shell
  enterShell = ''
    # Sync CLAUDE.md to AGENTS.md on shell entry
    if [ -n "$DEVENV_ROOT" ] && [ -d "$DEVENV_ROOT/.git" ]; then
      echo ""
      echo "🔄 Running CLAUDE.md sync..."
      "$DEVENV_ROOT/scripts/sync-claude-md.sh" "$DEVENV_ROOT" || true
    fi
  '';
}
