{ pkgs, ... }:
let
  # Create a wrapper script that works in any repo
  syncHook = pkgs.writeShellScriptBin "claude-md-sync-hook" ''
        #!/usr/bin/env bash
        set -euo pipefail
        
        # Find repo root (where .git is)
        REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
        cd "$REPO_ROOT"
        
        # Check if standalone script exists in repo
        if [ -f "$REPO_ROOT/scripts/sync-claude-md.sh" ]; then
          exec "$REPO_ROOT/scripts/sync-claude-md.sh" "$REPO_ROOT"
        fi
        
        # Inline sync logic (fallback when standalone script not available)
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
        done < <(git ls-files 2>/dev/null | grep -E '(^|/)AGENTS\.md$|(^|/)CLAUDE\.md$' || true)
        
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
          
          echo "  Processing: $dir"
          
          # Case 1: AGENTS.md exists as regular file
          if [ -f "$agents_file" ] && [ ! -L "$agents_file" ]; then
            if [ -L "$claude_file" ]; then
              target=$(readlink "$claude_file")
              if [ "$target" = "AGENTS.md" ]; then
                echo "    ✅ CLAUDE.md -> AGENTS.md (already synced)"
              else
                rm "$claude_file"
                ln -s "AGENTS.md" "$claude_file"
                echo "    ✅ Fixed: CLAUDE.md -> AGENTS.md"
              fi
            elif [ -f "$claude_file" ]; then
              rm "$claude_file"
              ln -s "AGENTS.md" "$claude_file"
              echo "    ✅ Replaced: CLAUDE.md -> AGENTS.md"
            else
              ln -s "AGENTS.md" "$claude_file"
              echo "    ✅ Created: CLAUDE.md -> AGENTS.md"
            fi
          fi
          
          # Case 2: CLAUDE.md exists as file, AGENTS.md doesn't
          if [ -f "$claude_file" ] && [ ! -L "$claude_file" ] && [ ! -e "$agents_file" ]; then
            mv "$claude_file" "$agents_file"
            echo "    ✅ Created: AGENTS.md (from CLAUDE.md)"
            ln -s "AGENTS.md" "$claude_file"
            echo "    ✅ Created: CLAUDE.md -> AGENTS.md"
          fi
        done
        
        echo "✅ Sync complete!"
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
          # Run the same inline logic as the pre-commit hook
          exec "${syncHook}/bin/claude-md-sync-hook"
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
