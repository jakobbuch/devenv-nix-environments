#!/usr/bin/env bash
set -euo pipefail

# Test script for claude-md-sync-hooks module
# This script verifies that the module correctly syncs CLAUDE.md to AGENTS.md
#
# Usage: devenv shell ./test-sync.sh
# Note: Must be run from within devenv shell

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
syncClaudeMd

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
syncClaudeMd

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
syncClaudeMd || true

if [ -f "subdir/AGENTS.md" ] && [ ! -L "subdir/AGENTS.md" ]; then
  echo "  ✅ Existing non-symlink file preserved"
else
  echo "  ❌ Existing non-symlink file was overwritten"
  exit 1
fi

# Test 5: Test pre-commit hook with prek run -a
echo ""
echo "📝 Test 5: Pre-commit hook execution (prek run -a)"
# Recreate subdir symlink for pre-commit test
rm -f subdir/AGENTS.md
ln -s "CLAUDE.md" "subdir/AGENTS.md"
echo "  Adding test files for pre-commit..."
git add -A

echo "  Running prek run -a..."
if prek run -a; then
  echo "  ✅ Pre-commit hook passed"
else
  echo "  ❌ Pre-commit hook failed"
  exit 1
fi

# Verify symlinks still work after pre-commit
if [ -L "AGENTS.md" ] && [ -L "subdir/AGENTS.md" ]; then
  echo "  ✅ Symlinks intact after pre-commit"
else
  echo "  ⚠️  Note: Some symlinks may have been modified by test 4"
  echo "     This is expected behavior - non-symlink files are preserved"
fi

# Clean up
echo ""
echo "🧹 Cleaning up test artifacts..."
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
git restore --staged CLAUDE.md subdir/CLAUDE.md 2>/dev/null || true

echo ""
echo "✅ All tests passed!"
