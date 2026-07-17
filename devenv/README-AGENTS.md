# AGENTS.md Validation Module

This module provides pre-commit hooks for validating AGENTS.md files in your repository.

## Usage

Add to your `devenv.nix`:

```nix
{
  imports = [
    ./devenv/agents-md-hooks-dev.nix  # Add this line
  ];
}
```

## Features

### Validation Checks

1. **File Existence** - Ensures all configured AGENTS.md files exist
2. **Structure Validation** - Verifies H1 title in first 5 lines
3. **Broken Link Detection** - Finds invalid Markdown references (e.g., `../modules/AGENTS.md`)

### Customization

Configure which files to validate via environment variable:

```bash
export AGENTS_MD_FILES="AGENTS.md docs/AGENTS.md src/AGENTS.md"
```

Or in your devenv.nix:

```nix
env.AGENTS_MD_FILES = "AGENTS.md docs/AGENTS.md";
```

### Commands

**Validate only:**
```bash
agents-md-check
```

**Auto-fix fixable issues:**
```bash
agents-md-fix
```

**Pre-commit hook:**
Runs automatically on commits (configured in `pre-commit.settings`)

## Example Output

```
============================================================
AGENTS.md Pre-commit Validation
============================================================

1. Checking file existence...
   ✅ All required files exist

2. Validating file structure...

3. Checking for broken Markdown links...

============================================================
RESULTS
============================================================

✅ All checks passed!

============================================================
VALIDATION PASSED
============================================================
```

## Error Example

```
============================================================
RESULTS
============================================================

ERRORS:
   ❌ BROKEN LINK: lib/AGENTS.md - References ../modules/AGENTS.md (use modules/nixos/ or modules/home/)

============================================================
VALIDATION FAILED
============================================================
```

## Fix

Run the auto-fix script:

```bash
agents-md-fix
```

This will correct known broken link patterns automatically.

## License

MIT License - same as devenv-nix-environments
