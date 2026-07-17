#!/usr/bin/env bash
set -euo pipefail

# Test script for claude-md-sync-hooks module
# Usage: devenv shell ./test-sync.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🧪 Testing claude-md-sync-hooks module..."
echo ""

# Clean up any previous test artifacts
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
mkdir -p subdir

# Test 1: Create AGENTS.md from scratch when neither exists
echo "📝 Test 1: Create AGENTS.md when neither file exists"
git clean -fd . 2>/dev/null || true

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -f "AGENTS.md" ] && [ ! -L "AGENTS.md" ]; then
  echo "  ✅ AGENTS.md created as regular file"
else
  echo "  ❌ AGENTS.md not created or is symlink"
  exit 1
fi

if [ -L "CLAUDE.md" ]; then
  target=$(readlink "CLAUDE.md")
  if [ "$target" = "AGENTS.md" ]; then
    echo "  ✅ CLAUDE.md -> AGENTS.md symlink created"
  else
    echo "  ❌ CLAUDE.md points to wrong target: $target"
    exit 1
  fi
else
  echo "  ❌ CLAUDE.md symlink not created"
  exit 1
fi

# Test 2: CLAUDE.md exists as file, should convert to AGENTS.md + symlink
echo ""
echo "📝 Test 2: CLAUDE.md exists - convert to AGENTS.md + symlink"
rm -f CLAUDE.md AGENTS.md
echo "# Original CLAUDE.md content" > CLAUDE.md

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -f "AGENTS.md" ] && [ ! -L "AGENTS.md" ]; then
  content=$(cat AGENTS.md)
  if [ "$content" = "# Original CLAUDE.md content" ]; then
    echo "  ✅ AGENTS.md created from CLAUDE.md content"
  else
    echo "  ❌ AGENTS.md content mismatch"
    exit 1
  fi
else
  echo "  ❌ AGENTS.md not created as regular file"
  exit 1
fi

if [ -L "CLAUDE.md" ]; then
  target=$(readlink "CLAUDE.md")
  if [ "$target" = "AGENTS.md" ]; then
    echo "  ✅ CLAUDE.md -> AGENTS.md symlink created"
  else
    echo "  ❌ CLAUDE.md points to wrong target: $target"
    exit 1
  fi
else
  echo "  ❌ CLAUDE.md is not symlink"
  exit 1
fi

# Test 3: AGENTS.md exists - should create CLAUDE.md symlink
echo ""
echo "📝 Test 3: AGENTS.md exists - create CLAUDE.md symlink"
rm -f CLAUDE.md AGENTS.md
echo "# AGENTS.md content" > AGENTS.md

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -f "AGENTS.md" ] && [ ! -L "AGENTS.md" ]; then
  echo "  ✅ AGENTS.md remains regular file"
else
  echo "  ❌ AGENTS.md was converted to symlink"
  exit 1
fi

if [ -L "CLAUDE.md" ]; then
  target=$(readlink "CLAUDE.md")
  if [ "$target" = "AGENTS.md" ]; then
    echo "  ✅ CLAUDE.md -> AGENTS.md symlink created"
  else
    echo "  ❌ Wrong symlink target: $target"
    exit 1
  fi
else
  echo "  ❌ CLAUDE.md symlink not created"
  exit 1
fi

# Test 4: Subdirectory support
echo ""
echo "📝 Test 4: Subdirectory sync"
mkdir -p subdir
echo "# Subdir AGENTS.md" > subdir/AGENTS.md

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -L "subdir/CLAUDE.md" ]; then
  target=$(readlink "subdir/CLAUDE.md")
  if [ "$target" = "AGENTS.md" ]; then
    echo "  ✅ subdir/CLAUDE.md -> AGENTS.md symlink created"
  else
    echo "  ❌ Wrong symlink target: $target"
    exit 1
  fi
else
  echo "  ❌ subdir/CLAUDE.md symlink not created"
  exit 1
fi

if [ -f "subdir/AGENTS.md" ] && [ ! -L "subdir/AGENTS.md" ]; then
  echo "  ✅ subdir/AGENTS.md remains regular file"
else
  echo "  ❌ subdir/AGENTS.md is symlink"
  exit 1
fi

# Test 5: Pre-commit hook with prek run -a
echo ""
echo "📝 Test 5: Pre-commit hook (prek run -a)"
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
mkdir -p subdir
echo "# Subdir AGENTS.md" > subdir/AGENTS.md

echo "  Running prek run -a..."
if prek run -a; then
  echo "  ✅ Pre-commit hook passed"
else
  echo "  ❌ Pre-commit hook failed"
  exit 1
fi

# Verify symlinks after pre-commit
if [ -L "subdir/CLAUDE.md" ]; then
  target=$(readlink "subdir/CLAUDE.md")
  if [ "$target" = "AGENTS.md" ]; then
    echo "  ✅ CLAUDE.md -> AGENTS.md symlink intact after pre-commit"
  else
    echo "  ❌ Wrong symlink target after pre-commit: $target"
    exit 1
  fi
else
  echo "  ❌ CLAUDE.md symlink broken after pre-commit"
  exit 1
fi

if [ -f "subdir/AGENTS.md" ] && [ ! -L "subdir/AGENTS.md" ]; then
  echo "  ✅ AGENTS.md remains regular file after pre-commit"
else
  echo "  ❌ AGENTS.md became symlink after pre-commit"
  exit 1
fi

# Clean up
echo ""
echo "🧹 Cleaning up test artifacts..."
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
git restore --staged . 2>/dev/null || true
git checkout -- . 2>/dev/null || true

echo ""
echo "✅ All tests passed!"
