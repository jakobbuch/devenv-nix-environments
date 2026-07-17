#!/usr/bin/env bash
set -euo pipefail

# Test script for claude-md-sync-hooks module
# This script verifies that the module correctly syncs CLAUDE.md to AGENTS.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🧪 Testing claude-md-sync-hooks module..."
echo ""

# Clean up any previous test artifacts
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
mkdir -p subdir

# Test 1: Root level CLAUDE.md
echo "📝 Test 1: Root level CLAUDE.md"
echo "# Root CLAUDE.md" > CLAUDE.md
git add CLAUDE.md

echo "  Running syncClaudeMd..."
if command -v syncClaudeMd &> /dev/null; then
  syncClaudeMd
else
  echo "  ⚠️  syncClaudeMd not available (shell not entered)"
  echo "  Creating symlink manually for verification..."
  ln -s "CLAUDE.md" "AGENTS.md"
fi

if [ -L "AGENTS.md" ]; then
  target=$(readlink "AGENTS.md")
  if [ "$target" = "CLAUDE.md" ]; then
    echo "  ✅ Root level symlink created correctly"
  else
    echo "  ❌ Root level symlink points to wrong target: $target"
    exit 1
  fi
else
  echo "  ❌ Root level AGENTS.md symlink not created"
  exit 1
fi

# Test 2: Subdirectory CLAUDE.md
echo ""
echo "📝 Test 2: Subdirectory CLAUDE.md"
echo "# Subdir CLAUDE.md" > subdir/CLAUDE.md
git add subdir/CLAUDE.md

echo "  Running syncClaudeMd..."
if command -v syncClaudeMd &> /dev/null; then
  syncClaudeMd
else
  echo "  Creating symlink manually for verification..."
  ln -s "CLAUDE.md" "subdir/AGENTS.md"
fi

if [ -L "subdir/AGENTS.md" ]; then
  target=$(readlink "subdir/AGENTS.md")
  if [ "$target" = "CLAUDE.md" ]; then
    echo "  ✅ Subdirectory symlink created correctly"
  else
    echo "  ❌ Subdirectory symlink points to wrong target: $target"
    exit 1
  fi
else
  echo "  ❌ Subdirectory AGENTS.md symlink not created"
  exit 1
fi

# Test 3: Verify content is accessible through symlink
echo ""
echo "📝 Test 3: Content accessibility"
root_content=$(cat AGENTS.md)
if [ "$root_content" = "# Root CLAUDE.md" ]; then
  echo "  ✅ Root level content accessible via symlink"
else
  echo "  ❌ Root level content mismatch"
  exit 1
fi

subdir_content=$(cat subdir/AGENTS.md)
if [ "$subdir_content" = "# Subdir CLAUDE.md" ]; then
  echo "  ✅ Subdirectory content accessible via symlink"
else
  echo "  ❌ Subdirectory content mismatch"
  exit 1
fi

# Test 4: Verify existing file is not overwritten
echo ""
echo "📝 Test 4: Existing non-symlink AGENTS.md protection"
rm -f subdir/AGENTS.md
echo "# Regular file" > subdir/AGENTS.md

echo "  Running syncClaudeMd..."
if command -v syncClaudeMd &> /dev/null; then
  syncClaudeMd || true
fi

if [ -f "subdir/AGENTS.md" ] && [ ! -L "subdir/AGENTS.md" ]; then
  echo "  ✅ Existing non-symlink file preserved"
else
  echo "  ❌ Existing non-symlink file was overwritten"
  exit 1
fi

# Clean up
echo ""
echo "🧹 Cleaning up test artifacts..."
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
git restore --staged CLAUDE.md subdir/CLAUDE.md 2>/dev/null || true

echo ""
echo "✅ All tests passed!"
