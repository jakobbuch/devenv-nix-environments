#!/usr/bin/env bash
# Flag kernel block-device names (nvme0n1, /dev/sdd): they reorder across boots. kernel-name-ok
# Exempt a line by adding `kernel-name-ok` (markdown: `<!-- kernel-name-ok -->`).
# Usage: check-kernel-device-names.sh FILE... | check-kernel-device-names.sh --all (every tracked file)
set -uo pipefail
# Paths never checked (ERE, repo-relative): single source, applies to FILE... and --all.
# Override with KERNEL_NAMES_EXCLUDE_RE; the default matches nothing.
readonly EXCLUDE_RE="${KERNEL_NAMES_EXCLUDE_RE:-^\$}"

# --all: check every tracked file (the hook runs this when the script itself changes).
if [ "${1:-}" = --all ] && [ "$#" -eq 1 ]; then
  cd "$(git rev-parse --show-toplevel)" || exit 2
  all=()
  while IFS= read -r -d '' f; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    [[ $f =~ $EXCLUDE_RE ]] && continue
    grep -Iq . "$f" 2>/dev/null || continue  # text files only
    all+=("$f")
  done < <(git ls-files -z)
  set -- "${all[@]}"
fi
readonly RE='\bnvme[0-9]+n[0-9]+(p[0-9]+)?\b|/dev/sd[a-z]+[0-9]*\b'
status=0
for file in "$@"; do
  [ -f "$file" ] || continue
  [[ $file =~ $EXCLUDE_RE ]] && continue
  out=$(grep -nIE "$RE" "$file" 2>/dev/null | grep -v 'kernel-name-ok' |
    sed "s|^\([0-9]*\):.*|$file:\1: kernel block-device name; use /dev/disk/by-id or the model|")
  if [ -n "$out" ]; then printf '%s\n' "$out"; status=1; fi
done
exit "$status"
