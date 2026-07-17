_: {
  # https://devenv.sh/git-hooks/
  git-hooks = {
    hooks = {
      # Custom hook to sync CLAUDE.md to AGENTS.md
      claude-md-sync = {
        enable = true;
        entry = "bash ''${DEVENV_ROOT}/scripts/sync-claude-md.sh ''${DEVENV_ROOT}";
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
      bash "$DEVENV_ROOT/scripts/sync-claude-md.sh" "$DEVENV_ROOT" || true
    fi
  '';
}
