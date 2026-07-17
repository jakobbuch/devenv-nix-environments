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

# Test 1: Create CLAUDE.md from scratch when neither exists
echo "📝 Test 1: Create CLAUDE.md when neither file exists"
git clean -fd . 2>/dev/null || true

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -f "CLAUDE.md" ] && [ ! -L "CLAUDE.md" ]; then
  echo "  ✅ CLAUDE.md created"
else
  echo "  ❌ CLAUDE.md not created or is symlink"
  exit 1
fi

if [ -L "AGENTS.md" ]; then
  target=$(readlink "AGENTS.md")
  if [ "$target" = "CLAUDE.md" ]; then
    echo "  ✅ AGENTS.md -> CLAUDE.md symlink created"
  else
    echo "  ❌ AGENTS.md points to wrong target: $target"
    exit 1
  fi
else
  echo "  ❌ AGENTS.md symlink not created"
  exit 1
fi

# Test 2: AGENTS.md exists, CLAUDE.md doesn't - should create CLAUDE.md from AGENTS.md
echo ""
echo "📝 Test 2: Create CLAUDE.md from existing AGENTS.md"
rm -f CLAUDE.md AGENTS.md
echo "# Existing AGENTS.md content" > AGENTS.md
git add AGENTS.md

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -f "CLAUDE.md" ]; then
  content=$(cat CLAUDE.md)
  if [ "$content" = "# Existing AGENTS.md content" ]; then
    echo "  ✅ CLAUDE.md created from AGENTS.md content"
  else
    echo "  ❌ CLAUDE.md content mismatch"
    exit 1
  fi
else
  echo "  ❌ CLAUDE.md not created"
  exit 1
fi

if [ -L "AGENTS.md" ]; then
  echo "  ✅ AGENTS.md is now symlink to CLAUDE.md"
else
  echo "  ❌ AGENTS.md is not symlink"
  exit 1
fi

# Test 3: CLAUDE.md exists - should create AGENTS.md symlink
echo ""
echo "📝 Test 3: CLAUDE.md exists - create AGENTS.md symlink"
rm -f AGENTS.md
echo "# CLAUDE.md content" > CLAUDE.md
git add CLAUDE.md

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -L "AGENTS.md" ]; then
  target=$(readlink "AGENTS.md")
  if [ "$target" = "CLAUDE.md" ]; then
    echo "  ✅ AGENTS.md -> CLAUDE.md symlink created"
  else
    echo "  ❌ Wrong symlink target: $target"
    exit 1
  fi
else
  echo "  ❌ AGENTS.md symlink not created"
  exit 1
fi

# Test 4: Subdirectory support
echo ""
echo "📝 Test 4: Subdirectory sync"
mkdir -p subdir
echo "# Subdir CLAUDE.md" > subdir/CLAUDE.md
git add subdir/CLAUDE.md

echo "  Running sync-claude-md.sh..."
bash ../../scripts/sync-claude-md.sh .

if [ -L "subdir/AGENTS.md" ]; then
  target=$(readlink "subdir/AGENTS.md")
  if [ "$target" = "CLAUDE.md" ]; then
    echo "  ✅ subdir/AGENTS.md -> CLAUDE.md symlink created"
  else
    echo "  ❌ Wrong symlink target: $target"
    exit 1
  fi
else
  echo "  ❌ subdir/AGENTS.md symlink not created"
  exit 1
fi

# Test 5: Pre-commit hook with prek run -a
echo ""
echo "📝 Test 5: Pre-commit hook (prek run -a)"
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
mkdir -p subdir
echo "# Test content" > subdir/CLAUDE.md
git add -A

echo "  Running prek run -a..."
if prek run -a; then
  echo "  ✅ Pre-commit hook passed"
else
  echo "  ❌ Pre-commit hook failed"
  exit 1
fi

# Verify symlinks after pre-commit
if [ -L "subdir/AGENTS.md" ]; then
  echo "  ✅ Symlinks intact after pre-commit"
else
  echo "  ❌ Symlinks broken after pre-commit"
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
