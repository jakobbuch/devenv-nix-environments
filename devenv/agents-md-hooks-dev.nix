{ config, pkgs, lib, ... }:
{
  # Pre-commit hook for validating AGENTS.md files
  # Ensures all AGENTS.md files exist, have consistent structure, and no broken links

  pre-commit.settings = {
    hooks.agents-md-validation = {
      enable = true;
      # Run on all AGENTS.md files
      files = ".*AGENTS\\.md$";
      # Use the validation script
      entry = "${config.pre-commit.settings.hooks.agents-md-validation.package}/bin/agents-md-check";
      # Always run (not just on staged files)
      pass_filenames = false;
    };
  };

  # Create the validation script package
  pre-commit.settings.hooks.agents-md-validation.package = pkgs.writeShellScriptBin "agents-md-check" ''
    #!/usr/bin/env bash
    set -euo pipefail

    REPO_ROOT="$(git rev-parse --show-toplevel)"
    FIX_MODE="$''{1:-}"

    echo "============================================================"
    echo "AGENTS.md Pre-commit Validation"
    echo "============================================================"
    echo ""

    # Temp files for messages
    ERROR_FILE=$(mktemp)
    WARNING_FILE=$(mktemp)
    trap 'rm -f "$ERROR_FILE" "$WARNING_FILE"' EXIT

    # Required files (configurable via environment)
    FILES="$''{AGENTS_MD_FILES:-AGENTS.md}"

    # 1. Check file existence
    echo "1. Checking file existence..."
    MISSING_COUNT=0
    for f in $FILES; do
        if [[ ! -f "$REPO_ROOT/$f" ]]; then
            echo "MISSING FILE: $f" >> "$ERROR_FILE"
            MISSING_COUNT=$((MISSING_COUNT + 1))
        fi
    done

    if [[ $MISSING_COUNT -eq 0 ]]; then
        echo "   ✅ All required files exist"
    else
        cat "$ERROR_FILE" | while read -r line; do
            echo "   ❌ $line"
        done
        exit 1
    fi
    echo ""

    # 2. Validate structure
    echo "2. Validating file structure..."
    for f in $FILES; do
        FILE_PATH="$REPO_ROOT/$f"
        if [[ ! -f "$FILE_PATH" ]]; then
            continue
        fi

        # Check for H1 title
        if ! head -5 "$FILE_PATH" | grep -q "^# "; then
            echo "STRUCTURE ERROR: $f - Missing H1 title in first 5 lines" >> "$ERROR_FILE"
        fi
    done

    # 3. Check for broken links (common patterns)
    echo "3. Checking for broken Markdown links..."
    BROKEN_COUNT=0
    for f in $FILES; do
        FILE_PATH="$REPO_ROOT/$f"
        if [[ ! -f "$FILE_PATH" ]]; then
            continue
        fi

        # Check for ../modules/AGENTS.md (ambiguous - doesn't exist)
        if grep -q "\.\./modules/AGENTS\.md" "$FILE_PATH"; then
            echo "BROKEN LINK: $f - References ../modules/AGENTS.md (use modules/nixos/ or modules/home/)" >> "$ERROR_FILE"
            BROKEN_COUNT=$((BROKEN_COUNT + 1))
        fi
    done

    echo ""

    # Report results
    echo "============================================================"
    echo "RESULTS"
    echo "============================================================"

    if [[ -s "$ERROR_FILE" ]]; then
        echo ""
        echo "ERRORS:"
        cat "$ERROR_FILE" | while read -r line; do
            echo "   ❌ $line"
        done
        echo ""
        echo "============================================================"
        echo "VALIDATION FAILED"
        echo "============================================================"
        exit 1
    else
        echo ""
        echo "============================================================"
        echo "✅ All checks passed!"
        echo "============================================================"
        echo "VALIDATION PASSED"
        echo "============================================================"
        exit 0
    fi
  '';

  # Optional: auto-fix script
  pre-commit.settings.hooks.agents-md-fix.package = pkgs.writeShellScriptBin "agents-md-fix" ''
    #!/usr/bin/env bash
    set -euo pipefail

    REPO_ROOT="$(git rev-parse --show-toplevel)"

    echo "Fixing broken AGENTS.md links..."

    # Fix ../modules/AGENTS.md → ../modules/home/AGENTS.md
    for f in AGENTS.md hosts/AGENTS.md modules/nixos/AGENTS.md modules/home/AGENTS.md lib/AGENTS.md parts/AGENTS.md pkgs/AGENTS.md filesystem/AGENTS.md .agents/AGENTS.md migration/unraid-to-nixos/AGENTS.md; do
        FILE_PATH="$REPO_ROOT/$f"
        if [[ -f "$FILE_PATH" ]]; then
            if grep -q "\.\./modules/AGENTS\.md" "$FILE_PATH"; then
                echo "Fixing $f..."
                sed -i 's|\.\./modules/AGENTS\.md|../modules/home/AGENTS.md|g' "$FILE_PATH"
            fi
        fi
    done

    echo "Done! Re-run validation to confirm."
  '';
}
