#!/usr/bin/env bash
set -euo pipefail

# sync-claude-md.sh - Sync CLAUDE.md files to AGENTS.md via symlinks
# This script can be used standalone or within devenv environments
#
# Usage:
#   ./sync-claude-md.sh              # Run in current directory
#   ./sync-claude-md.sh /path/to/repo # Run in specified directory
#
# For non-Nix users: Copy this script to your project root and run it manually
# before committing, or add it to your pre-commit hooks.

REPO_ROOT="${1:-$(pwd)}"

cd "$REPO_ROOT"

echo "🔄 Syncing CLAUDE.md files to AGENTS.md..."

# Find all CLAUDE.md files in the repository (excluding .git)
claude_files=()
while IFS= read -r file; do
  claude_files+=("$file")
done < <(git ls-files 2>/dev/null | grep -E '^CLAUDE\.md$|/CLAUDE\.md$' || true)

if [ ${#claude_files[@]} -eq 0 ]; then
  echo "✅ No CLAUDE.md files found. Nothing to sync."
  exit 0
fi

echo "📄 Found ${#claude_files[@]} CLAUDE.md file(s):"

for claude_file in "${claude_files[@]}"; do
  # Get the directory containing the CLAUDE.md file
  dir=$(dirname "$claude_file")
  agents_file="$dir/AGENTS.md"
  
  # Remove existing AGENTS.md if it's not a symlink
  if [ -e "$agents_file" ] && [ ! -L "$agents_file" ]; then
    echo "  ⚠️  Skipping $agents_file (exists but not a symlink)"
    continue
  fi
  
  # Remove existing symlink if it points to wrong target
  if [ -L "$agents_file" ]; then
    current_target=$(readlink "$agents_file")
    if [ "$current_target" != "CLAUDE.md" ]; then
      echo "  🗑️  Removing stale symlink $agents_file -> $current_target"
      rm "$agents_file"
    fi
  fi
  
  # Create symlink if it doesn't exist
  if [ ! -L "$agents_file" ]; then
    ln -s "CLAUDE.md" "$agents_file"
    echo "  ✅ Created: $agents_file -> CLAUDE.md"
  else
    echo "  ✅ Exists: $agents_file -> CLAUDE.md"
  fi
done

echo "✅ Sync complete!"
