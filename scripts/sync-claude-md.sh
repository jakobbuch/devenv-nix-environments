#!/usr/bin/env bash
set -euo pipefail

# sync-claude-md.sh - Sync CLAUDE.md and AGENTS.md for Claude/OpenCode collaboration
#
# AGENTS.md is the SOURCE file (for OpenCode users)
# CLAUDE.md is a SYMLINK to AGENTS.md (for Claude users)
#
# This script ensures:
# - AGENTS.md always exists as a regular file
# - CLAUDE.md is always a symlink to AGENTS.md
# - If only CLAUDE.md exists (as file), convert to AGENTS.md + symlink
# - If neither exists, create AGENTS.md with default template + symlink
#
# Usage:
#   ./sync-claude-md.sh              # Run in current directory
#   ./sync-claude-md.sh /path/to/repo # Run in specified directory

REPO_ROOT="${1:-$(pwd)}"

cd "$REPO_ROOT"

echo "🔄 Syncing CLAUDE.md and AGENTS.md for collaboration..."
echo "   AGENTS.md = source file (OpenCode)"
echo "   CLAUDE.md = symlink to AGENTS.md (Claude)"
echo ""

# Find all directories containing CLAUDE.md or AGENTS.md files (tracked or untracked)
dirs_to_sync=()

# Find directories with CLAUDE.md (tracked)
while IFS= read -r file; do
  dir=$(dirname "$file")
  if [[ ! " ${dirs_to_sync[*]} " =~ ${dir} ]]; then
    dirs_to_sync+=("$dir")
  fi
done < <(git ls-files 2>/dev/null | grep -E '(^|/)CLAUDE\.md$' || true)

# Find directories with AGENTS.md (tracked)
while IFS= read -r file; do
  dir=$(dirname "$file")
  if [[ ! " ${dirs_to_sync[*]} " =~ ${dir} ]]; then
    dirs_to_sync+=("$dir")
  fi
done < <(git ls-files 2>/dev/null | grep -E '(^|/)AGENTS\.md$' || true)

# Also check for untracked files in root
if [ -f "CLAUDE.md" ] && [[ ! " ${dirs_to_sync[*]} " =~ . ]]; then
  dirs_to_sync+=(".")
fi
if [ -f "AGENTS.md" ] && [[ ! " ${dirs_to_sync[*]} " =~ . ]]; then
  dirs_to_sync+=(".")
fi

# If no files found at all, create root-level AGENTS.md
if [ ${#dirs_to_sync[@]} -eq 0 ]; then
  echo "📄 No CLAUDE.md or AGENTS.md files found. Creating root-level files..."
  
  if [ ! -f "AGENTS.md" ]; then
    # Create default AGENTS.md
    cat > AGENTS.md << 'TEMPLATE'
# AGENTS.md

Project guidelines and context for AI assistants (OpenCode, Claude, etc.).

## Project Overview

<!-- Describe your project here -->

## Development Guidelines

<!-- Add coding standards, architecture notes, etc. -->

## Important Files

<!-- List key files and their purposes -->
TEMPLATE
    echo "  ✅ Created: AGENTS.md (default template)"
  fi
  
  # Create CLAUDE.md symlink to AGENTS.md
  if [ -L "CLAUDE.md" ]; then
    target=$(readlink "CLAUDE.md")
    if [ "$target" != "AGENTS.md" ]; then
      rm "CLAUDE.md"
      ln -s "AGENTS.md" "CLAUDE.md"
      echo "  ✅ Fixed: CLAUDE.md -> AGENTS.md"
    else
      echo "  ✅ CLAUDE.md -> AGENTS.md (already correct)"
    fi
  elif [ -f "CLAUDE.md" ]; then
    # CLAUDE.md is a regular file, replace with symlink
    rm "CLAUDE.md"
    ln -s "AGENTS.md" "CLAUDE.md"
    echo "  ✅ Replaced: CLAUDE.md -> AGENTS.md"
  else
    ln -s "AGENTS.md" "CLAUDE.md"
    echo "  ✅ Created: CLAUDE.md -> AGENTS.md"
  fi
  
  echo "✅ Sync complete!"
  exit 0
fi

echo "📄 Found ${#dirs_to_sync[@]} director(ies) to sync:"

for dir in "${dirs_to_sync[@]}"; do
  claude_file="$dir/CLAUDE.md"
  agents_file="$dir/AGENTS.md"
  
  echo "  Processing: $dir"
  
  # Case 1: AGENTS.md exists as regular file (correct state)
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
      # CLAUDE.md is regular file, replace with symlink
      rm "$claude_file"
      ln -s "AGENTS.md" "$claude_file"
      echo "    ✅ Replaced: CLAUDE.md -> AGENTS.md"
    else
      # CLAUDE.md doesn't exist
      ln -s "AGENTS.md" "$claude_file"
      echo "    ✅ Created: CLAUDE.md -> AGENTS.md"
    fi
  fi
  
  # Case 2: CLAUDE.md exists as regular file, AGENTS.md doesn't exist
  if [ -f "$claude_file" ] && [ ! -L "$claude_file" ] && [ ! -e "$agents_file" ]; then
    # Move CLAUDE.md content to AGENTS.md
    mv "$claude_file" "$agents_file"
    echo "    ✅ Created: AGENTS.md (from CLAUDE.md)"
    
    # Create CLAUDE.md symlink
    ln -s "AGENTS.md" "$claude_file"
    echo "    ✅ Created: CLAUDE.md -> AGENTS.md"
  fi
  
  # Case 3: CLAUDE.md is symlink to wrong target
  if [ -L "$claude_file" ]; then
    target=$(readlink "$claude_file")
    if [ "$target" != "AGENTS.md" ]; then
      rm "$claude_file"
      ln -s "AGENTS.md" "$claude_file"
      echo "    ✅ Fixed: CLAUDE.md -> AGENTS.md (was -> $target)"
    fi
  fi
  
  # Case 4: AGENTS.md is symlink (wrong! should be regular file)
  if [ -L "$agents_file" ]; then
    target=$(readlink "$agents_file")
    if [ -f "$dir/$target" ]; then
      # Replace AGENTS.md symlink with actual file
      cp "$dir/$target" "$agents_file.tmp"
      rm "$agents_file"
      mv "$agents_file.tmp" "$agents_file"
      echo "    ✅ Converted: AGENTS.md (was symlink, now file)"
      
      # Fix CLAUDE.md symlink
      if [ -L "$claude_file" ]; then
        rm "$claude_file"
      elif [ -f "$claude_file" ]; then
        rm "$claude_file"
      fi
      ln -s "AGENTS.md" "$claude_file"
      echo "    ✅ Fixed: CLAUDE.md -> AGENTS.md"
    fi
  fi
done

echo "✅ Sync complete!"
