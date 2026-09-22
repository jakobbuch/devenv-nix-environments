#!/usr/bin/env bash
# sync-claude-md.sh - keep every AGENTS.md readable by Claude Code.
#
# AGENTS.md is the single instruction source. Claude Code reads it natively
# since 2.1.277, but only as a fallback: a CLAUDE.md (or .claude/CLAUDE.md) at
# the repo root switches the fallback off for the whole tree, and a real
# CLAUDE.md beside an AGENTS.md hides that file unless it is a symlink to it or
# opens with the "@AGENTS.md" import. Hence the invariant:
#
#   - no root CLAUDE.md: no companion is required; one that exists must be a
#     symlink or open with @AGENTS.md (Claude-only lines may follow);
#   - a root CLAUDE.md: every AGENTS.md gets a companion, created as a symlink.
#
# Drift is repaired: a copy of AGENTS.md becomes a symlink, a diverged
# CLAUDE.md is merged into AGENTS.md first. Any change exits non-zero so the
# author re-stages and reviews.
#
# Usage: ./sync-claude-md.sh [/path/to/repo]

set -euo pipefail

cd "${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

changed=0
review=0

link() { # $1 = directory
  ln -s AGENTS.md "$1/CLAUDE.md"
  echo "linked $1/CLAUDE.md -> AGENTS.md"
  changed=1
}

# A root CLAUDE.md (real file or symlink) disables the native fallback, so
# every AGENTS.md below it then needs its own companion.
require_companion=0
if [ -e CLAUDE.md ] || [ -L CLAUDE.md ] || [ -e .claude/CLAUDE.md ]; then
  require_companion=1
fi

dirs=$(git ls-files --cached --others --exclude-standard 2>/dev/null |
  grep -E '(^|/)(AGENTS|CLAUDE)\.md$' |
  grep -vE '(^|/)(node_modules|\.venv|\.git)/' |
  xargs -r -n1 dirname | sort -u || true)

for dir in $dirs; do
  agents="$dir/AGENTS.md"
  claude="$dir/CLAUDE.md"

  # A lone CLAUDE.md (no AGENTS.md beside it, .claude/CLAUDE.md included) is
  # the author's own file; nothing here may rewrite it.
  [ -f "$agents" ] || continue

  if [ -L "$claude" ]; then
    [ "$(readlink "$claude")" = "AGENTS.md" ] && continue
    rm "$claude"
    link "$dir"
    continue
  fi

  if [ ! -e "$claude" ]; then
    [ "$require_companion" = 1 ] && link "$dir"
    continue
  fi

  # First non-blank line is the import: Claude-only rules may follow it.
  first=$(sed -n '/[^[:space:]]/{s/^[[:space:]]*//;s/[[:space:]]*$//;p;q}' "$claude")
  [ "$first" = "@AGENTS.md" ] && continue

  if [ "$(cat "$claude")" = "$(cat "$agents")" ]; then
    rm "$claude"
    link "$dir"
    continue
  fi

  printf '\n## Merged from CLAUDE.md (%s)\n\n' "$(date +%F)" >>"$agents"
  cat "$claude" >>"$agents"
  rm "$claude"
  link "$dir"
  echo "REVIEW: $claude had diverged; its content was appended to $agents" >&2
  review=1
done

if [ "$changed" = 1 ] || [ "$review" = 1 ]; then
  echo "AGENTS.md/CLAUDE.md links changed. Re-stage the files and commit again." >&2
  exit 1
fi
exit 0
