#!/usr/bin/env bash
# Enforce no `*` wildcard before more command text in Claude Code permissions.allow Bash rules.
# Usage: check-claude-permissions.sh [FILE...] (default: $CLAUDE_SETTINGS_FILES, space-separated repo-relative
# paths, else .claude/settings.json)
set -uo pipefail

if [ "$#" -eq 0 ]; then
  root="$(git rev-parse --show-toplevel)" || exit 2
  set --
  # shellcheck disable=SC2086 # intentional word splitting of the path list
  for p in ${CLAUDE_SETTINGS_FILES:-.claude/settings.json}; do set -- "$@" "$root/$p"; done
fi

status=0
for f in "$@"; do
  [ -f "$f" ] || continue
  while IFS= read -r rule; do
    inner="${rule#Bash(}"
    inner="${inner%)}"
    inner="${inner%"${inner##*[![:space:]]}"}" # drop trailing spaces
    head="${inner%\*}"                         # drop one trailing *
    case "$head" in
      *'*'*)
        echo "$f: $rule: wildcard before the rest of the command; replace * with the exact value or move it to the end"
        status=1
        ;;
    esac
  done < <(jq -r '.permissions.allow[]? | strings | select(test("^Bash\\("))' "$f")
done
exit "$status"
