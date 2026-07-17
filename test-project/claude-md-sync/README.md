# CLAUDE.md Sync Hooks Test

This test project verifies the `claude-md-sync-hooks` module functionality.

## What it Tests

1. **Root level sync**: `CLAUDE.md` → `AGENTS.md` symlink at repository root
2. **Subdirectory sync**: `subdir/CLAUDE.md` → `subdir/AGENTS.md` symlink
3. **Content accessibility**: Verify content is readable through symlinks
4. **File protection**: Existing non-symlink `AGENTS.md` files are not overwritten
5. **Pre-commit hook**: Verify `prek run -a` executes the sync hook successfully

## How to Run

### Run Full Test Suite (Recommended)

```bash
cd test-project/claude-md-sync
devenv shell ./test-sync.sh
```

This runs all tests including the pre-commit hook verification.

### Manual Verification

```bash
cd test-project/claude-md-sync
devenv shell

# Create test CLAUDE.md files
echo "# Test" > CLAUDE.md
mkdir -p subdir
echo "# Subdir Test" > subdir/CLAUDE.md
git add .

# Run sync (automatic in enterShell, or manual)
syncClaudeMd

# Verify symlinks
ls -la AGENTS.md subdir/AGENTS.md
cat AGENTS.md
cat subdir/AGENTS.md

# Test pre-commit hook
prek run -a
```

## Expected Behavior

- `AGENTS.md` should be a symlink to `CLAUDE.md`
- `subdir/AGENTS.md` should be a symlink to `subdir/CLAUDE.md`
- Content should be accessible through both paths
- Pre-commit hook (`prek run -a`) should execute successfully
- Existing non-symlink `AGENTS.md` files should be preserved

## Standalone Script for Non-Nix Users

A standalone script is available at `scripts/sync-claude-md.sh` in the root of this repository.

**Usage:**

```bash
# Copy to your project
cp /path/to/devenv-nix-environments/scripts/sync-claude-md.sh /your/project/

# Run manually before committing
./sync-claude-md.sh

# Or add to your pre-commit config
# .pre-commit-config.yaml:
# - repo: local
#   hooks:
#     - id: sync-claude-md
#       name: Sync CLAUDE.md to AGENTS.md
#       entry: ./sync-claude-md.sh
#       language: script
#       pass_filenames: false
```

## Cleanup

The test script automatically cleans up test artifacts. To manually clean:

```bash
rm -f CLAUDE.md AGENTS.md
rm -rf subdir
```

## Module Usage

To use the `claude-md-sync-hooks` module in your project:

```nix
# devenv.nix
{ inputs, ... }: {
  imports = [
    inputs.devenv-modules.devenvModules.claude-md-sync-hooks
  ];
}
```

This provides:

- `syncClaudeMd` script (or `sync-claude-md.sh` from scripts/)
- Automatic sync on shell entry
- Pre-commit hook that runs before every commit
