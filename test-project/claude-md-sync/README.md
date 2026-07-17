# CLAUDE.md Sync Hooks Test

This test project verifies the `claude-md-sync-hooks` module functionality.

## What it Tests

1. **Root level sync**: `CLAUDE.md` → `AGENTS.md` symlink at repository root
2. **Subdirectory sync**: `subdir/CLAUDE.md` → `subdir/AGENTS.md` symlink
3. **Content accessibility**: Verify content is readable through symlinks
4. **File protection**: Existing non-symlink `AGENTS.md` files are not overwritten

## How to Run

### Option 1: Automated Test Script

```bash
cd test-project/claude-md-sync
devenv shell
./test-sync.sh
```

**Note**: Run from within the devenv shell to ensure the `syncClaudeMd` script is available.

### Option 2: Manual Verification

```bash
cd test-project/claude-md-sync
devenv shell

# Create test CLAUDE.md files
echo "# Test" > CLAUDE.md
mkdir -p subdir
echo "# Subdir Test" > subdir/CLAUDE.md
git add .

# Run sync (automatic in enterShell)
syncClaudeMd

# Verify symlinks
ls -la AGENTS.md subdir/AGENTS.md
cat AGENTS.md
cat subdir/AGENTS.md
```

## Expected Behavior

- `AGENTS.md` should be a symlink to `CLAUDE.md`
- `subdir/AGENTS.md` should be a symlink to `subdir/CLAUDE.md`
- Content should be accessible through both paths
- Pre-commit hook runs sync before commits (when in devenv shell)

## Cleanup

The test script automatically cleans up test artifacts. To manually clean:

```bash
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
```

## Pre-commit Hook

The module includes a pre-commit hook that automatically syncs CLAUDE.md files.
**Important**: The hook only works when commits are made from within the devenv shell.
For commits outside the shell, run `syncClaudeMd` manually before committing.
