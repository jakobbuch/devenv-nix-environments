# CLAUDE.md Sync Hooks Test

This test project verifies the `claude-md-sync-hooks` module functionality.

## Architecture

```text
AGENTS.md  = SOURCE FILE (edited by OpenCode users)
   ↑
   └── CLAUDE.md (symlink → AGENTS.md, for Claude users)
```text

**Key principle:** `AGENTS.md` is always the regular file. `CLAUDE.md` is always a symlink.

## What it Tests

1. **Create from scratch**: No files → Creates `AGENTS.md` (template) + `CLAUDE.md` symlink
2. **CLAUDE.md exists**: Converts to `AGENTS.md` + symlink (preserves content)
3. **AGENTS.md exists**: Creates `CLAUDE.md` symlink
4. **Subdirectory support**: Works in nested directories
5. **Pre-commit hook**: `prek run -a` executes sync correctly

## How to Run

### Run Full Test Suite

```bash
cd test-project/claude-md-sync
devenv shell ./test-sync.sh
```text

### Manual Verification

```bash
cd test-project/claude-md-sync
devenv shell

# Test 1: Create from scratch
rm -f CLAUDE.md AGENTS.md
syncClaudeMd
ls -la  # AGENTS.md (file), CLAUDE.md -> AGENTS.md (symlink)

# Test 2: Convert CLAUDE.md to AGENTS.md
rm -f CLAUDE.md AGENTS.md
echo "# My content" > CLAUDE.md
syncClaudeMd
ls -la  # AGENTS.md (file with content), CLAUDE.md -> AGENTS.md

# Test pre-commit hook
prek run -a
```text

## Standalone Script for Non-Nix Users

**Location:** `scripts/sync-claude-md.sh`

**Usage:**

```bash
# Copy to your project
cp /path/to/devenv-nix-environments/scripts/sync-claude-md.sh /your/project/

# Run manually before committing
./sync-claude-md.sh

# Or specify a different repository
./sync-claude-md.sh /path/to/repo
```text

**Add to your `.pre-commit-config.yaml`:**

```yaml
- repo: local
  hooks:
    - id: sync-claude-md
      name: Sync CLAUDE.md to AGENTS.md
      entry: ./sync-claude-md.sh
      language: script
      pass_filenames: false
```text

## Module Usage

```nix
# devenv.nix
{ inputs, ... }: {
  imports = [
    inputs.devenv-modules.devenvModules.claude-md-sync-hooks
  ];
}
```text

**Provides:**

- Pre-commit hook that syncs before every commit
- Automatic sync on shell entry
- Self-contained: works with or without standalone script
- If `scripts/sync-claude-md.sh` exists in your repo, uses it
- Otherwise, uses inline sync logic (no external files needed)

## Workflow

**OpenCode users:**

1. Edit `AGENTS.md` directly
2. Changes automatically visible via `CLAUDE.md` symlink

**Claude users:**

1. Edit `CLAUDE.md` (which writes to `AGENTS.md`)
2. OpenCode users see changes in `AGENTS.md`

**Both see the same content!**
