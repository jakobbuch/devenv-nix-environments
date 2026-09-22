{ pkgs, ... }:
let
  # The logic lives in scripts/sync-claude-md.sh so the Nix hook and the
  # standalone script for non-Nix projects can never drift apart. A repo may
  # ship its own scripts/sync-claude-md.sh to override it.
  syncHook = pkgs.writeShellScriptBin "claude-md-sync-hook" ''
    set -euo pipefail
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    cd "$REPO_ROOT"
    if [ -f "$REPO_ROOT/scripts/sync-claude-md.sh" ]; then
      exec bash "$REPO_ROOT/scripts/sync-claude-md.sh" "$REPO_ROOT"
    fi

    ${builtins.readFile ../scripts/sync-claude-md.sh}
  '';
in
{
  # https://devenv.sh/scripts/
  scripts = {
    # Keep every AGENTS.md readable by Claude Code (see the script's header)
    syncClaudeMd = {
      exec = "exec ${syncHook}/bin/claude-md-sync-hook";
      description = "Sync CLAUDE.md companions to AGENTS.md";
    };
  };

  # https://devenv.sh/git-hooks/
  git-hooks = {
    hooks = {
      claude-md-sync = {
        enable = true;
        entry = "${syncHook}/bin/claude-md-sync-hook";
        language = "system";
        description = "Sync CLAUDE.md companions to AGENTS.md";
        stages = [ "pre-commit" ];
        pass_filenames = false;
      };
    };
  };

}
