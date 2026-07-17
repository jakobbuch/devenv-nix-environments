#!/usr/bin/env bash
set -euo pipefail

# sync-claude-md.sh - Sync CLAUDE.md and AGENTS.md for Claude/OpenCode collaboration
#
# This script ensures CLAUDE.md and AGENTS.md point to the same content:
# - If CLAUDE.md exists: creates AGENTS.md as symlink to it
# - If AGENTS.md exists (but not CLAUDE.md): creates CLAUDE.md from it, then symlinks
# - If neither exists: creates empty CLAUDE.md and symlinks AGENTS.md to it
#
# Usage:
#   ./sync-claude-md.sh              # Run in current directory
#   ./sync-claude-md.sh /path/to/repo # Run in specified directory

REPO_ROOT="${1:-$(pwd)}"

cd "$REPO_ROOT"

echo "🔄 Syncing CLAUDE.md and AGENTS.md for collaboration..."

# Find all directories containing CLAUDE.md or AGENTS.md files (tracked or untracked)
dirs_to_sync=()

# Find directories with CLAUDE.md (tracked)
while IFS= read -r file; do
  dir=$(dirname "$file")
  if [[ ! " ${dirs_to_sync[*]} " =~ " ${dir} " ]]; then
    dirs_to_sync+=("$dir")
  fi
done < <(git ls-files 2>/dev/null | grep -E '(^|/)CLAUDE\.md$' || true)

# Find directories with AGENTS.md (tracked)
while IFS= read -r file; do
  dir=$(dirname "$file")
  if [[ ! " ${dirs_to_sync[*]} " =~ " ${dir} " ]]; then
    dirs_to_sync+=("$dir")
  fi
done < <(git ls-files 2>/dev/null | grep -E '(^|/)AGENTS\.md$' || true)

# Also check for untracked files in root
if [ -f "CLAUDE.md" ] && [[ ! " ${dirs_to_sync[*]} " =~ " . " ]]; then
  dirs_to_sync+=(".")
fi
if [ -f "AGENTS.md" ] && [[ ! " ${dirs_to_sync[*]} " =~ " . " ]]; then
  dirs_to_sync+=(".")
fi

# If no files found at all, create root-level CLAUDE.md
if [ ${#dirs_to_sync[@]} -eq 0 ]; then
  echo "📄 No CLAUDE.md or AGENTS.md files found. Creating root-level files..."
  
  if [ ! -f "CLAUDE.md" ] && [ ! -f "AGENTS.md" ]; then
    # Create default CLAUDE.md
    cat > CLAUDE.md << 'TEMPLATE'
# CLAUDE.md

Project guidelines and context for Claude AI assistant.

## Project Overview

<!-- Describe your project here -->

## Development Guidelines

<!-- Add coding standards, architecture notes, etc. -->

## Important Files

<!-- List key files and their purposes -->
TEMPLATE
    echo "  ✅ Created: CLAUDE.md (default template)"
  elif [ -f "AGENTS.md" ] && [ ! -f "CLAUDE.md" ]; then
    # AGENTS.md exists, use it as source
    cp "AGENTS.md" "CLAUDE.md"
    echo "  ✅ Created: CLAUDE.md (from AGENTS.md)"
  fi
  
  # Create symlink
  if [ -f "AGENTS.md" ] && [ ! -L "AGENTS.md" ]; then
    rm "AGENTS.md"
  fi
  if [ ! -L "AGENTS.md" ]; then
    ln -s "CLAUDE.md" "AGENTS.md"
    echo "  ✅ Created: AGENTS.md -> CLAUDE.md"
  fi
  
  echo "✅ Sync complete!"
  exit 0
fi

echo "📄 Found ${#dirs_to_sync[@]} director(ies) to sync:"

for dir in "${dirs_to_sync[@]}"; do
  claude_file="$dir/CLAUDE.md"
  agents_file="$dir/AGENTS.md"
  
  echo "  Processing: $dir"
  
  # Case 1: CLAUDE.md exists as regular file
  if [ -f "$claude_file" ] && [ ! -L "$claude_file" ]; then
    if [ -L "$agents_file" ]; then
      # Already symlinked correctly
      echo "    ✅ AGENTS.md -> CLAUDE.md (already synced)"
    elif [ -f "$agents_file" ]; then
      # AGENTS.md is regular file, replace with symlink
      rm "$agents_file"
      ln -s "CLAUDE.md" "$agents_file"
      echo "    ✅ Replaced: AGENTS.md -> CLAUDE.md"
    else
      # AGENTS.md doesn't exist
      ln -s "CLAUDE.md" "$agents_file"
      echo "    ✅ Created: AGENTS.md -> CLAUDE.md"
    fi
  fi
  
  # Case 2: AGENTS.md exists as regular file, CLAUDE.md doesn't exist
  if [ -f "$agents_file" ] && [ ! -L "$agents_file" ] && [ ! -e "$claude_file" ]; then
    # Copy AGENTS.md content to CLAUDE.md
    cp "$agents_file" "$claude_file"
    echo "    ✅ Created: CLAUDE.md (from AGENTS.md)"
    
    # Replace AGENTS.md with symlink
    rm "$agents_file"
    ln -s "CLAUDE.md" "$agents_file"
    echo "    ✅ Replaced: AGENTS.md -> CLAUDE.md"
  fi
  
  # Case 3: Both are symlinks (already synced)
  if [ -L "$claude_file" ] && [ -L "$agents_file" ]; then
    echo "    ✅ Both are symlinks (already synced)"
  fi
  
  # Case 4: CLAUDE.md is symlink to AGENTS.md (reverse sync)
  if [ -L "$claude_file" ]; then
    target=$(readlink "$claude_file")
    if [ "$target" = "AGENTS.md" ]; then
      # Reverse the symlink: make AGENTS.md -> CLAUDE.md instead
      rm "$claude_file"
      cp "$agents_file" "CLAUDE.md.tmp"
      mv "CLAUDE.md.tmp" "$claude_file"
      rm "$agents_file"
      ln -s "CLAUDE.md" "$agents_file"
      echo "    ✅ Fixed: AGENTS.md -> CLAUDE.md (was reversed)"
    fi
  fi
done

echo "✅ Sync complete!"
