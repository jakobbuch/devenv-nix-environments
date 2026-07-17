{ pkgs, ... }:
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
  # https://devenv.sh/scripts/
  scripts = {
    # Sync all CLAUDE.md files to AGENTS.md via symlinks
    syncClaudeMd = {
      exec = ''
                #!/usr/bin/env bash
                set -euo pipefail
                
                # Find repo root (where .git is)
                REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
                
                # Check if standalone script exists in repo, otherwise use inline logic
                if [ -f "$REPO_ROOT/scripts/sync-claude-md.sh" ]; then
                  exec "$REPO_ROOT/scripts/sync-claude-md.sh" "$REPO_ROOT"
                else
                  # Inline sync logic for when standalone script is not available
                  cd "$REPO_ROOT"
                  echo "🔄 Syncing CLAUDE.md and AGENTS.md for collaboration..."
                  echo "   AGENTS.md = source file (OpenCode)"
                  echo "   CLAUDE.md = symlink to AGENTS.md (Claude)"
                  
                  # Find directories with AGENTS.md or CLAUDE.md
                  dirs_to_sync=()
                  while IFS= read -r file; do
                    dir=$(dirname "$file")
                    if [[ ! " ''${dirs_to_sync[*]} " =~ " ''${dir} " ]]; then
                      dirs_to_sync+=("$dir")
                    fi
                  done < <(git ls-files 2>/dev/null | grep -E '(^|/)AGENTS\.md$' || true)
                  
                  # If no files found, create root-level AGENTS.md
                  if [ ''${#dirs_to_sync[@]} -eq 0 ]; then
                    if [ ! -f "AGENTS.md" ]; then
                      cat > AGENTS.md << 'TEMPLATE'
        # AGENTS.md
        Project guidelines and context for AI assistants.
        TEMPLATE
                      echo "  ✅ Created: AGENTS.md (default template)"
                    fi
                    if [ ! -L "CLAUDE.md" ]; then
                      [ -f "CLAUDE.md" ] && rm "CLAUDE.md"
                      ln -s "AGENTS.md" "CLAUDE.md"
                      echo "  ✅ Created: CLAUDE.md -> AGENTS.md"
                    fi
                    echo "✅ Sync complete!"
                    exit 0
                  fi
                  
                  # Process each directory
                  for dir in "''${dirs_to_sync[@]}"; do
                    agents_file="$dir/AGENTS.md"
                    claude_file="$dir/CLAUDE.md"
                    if [ -f "$agents_file" ] && [ ! -L "$agents_file" ]; then
                      if [ ! -L "$claude_file" ]; then
                        [ -f "$claude_file" ] && rm "$claude_file"
                        ln -s "AGENTS.md" "$claude_file"
                        echo "  ✅ Created: $claude_file -> AGENTS.md"
                      fi
                    fi
                  done
                  echo "✅ Sync complete!"
                fi
      '';
      description = "Sync CLAUDE.md files to AGENTS.md";
    };
  };

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
      syncClaudeMd || true
    fi
  '';
}
