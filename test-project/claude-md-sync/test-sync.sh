#!/usr/bin/env bash
# Test the claude-md-sync rules against throwaway git repos.
# Usage: ./test-sync.sh [path-to-sync-script]

SYNC=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../scripts" && pwd)/sync-claude-md.sh}
ROOT=$(mktemp -d)
fail=0

mk() { # $1 = case name -> prints the repo path
  d="$ROOT/$1"
  mkdir -p "$d"
  git -C "$d" init -q
  echo "# agents" >"$d/AGENTS.md"
  echo "$d"
}

state() { # $1 = repo, $2 = relative path
  p="$1/$2"
  if [ -L "$p" ]; then echo "symlink->$(readlink "$p")"
  elif [ -f "$p" ]; then echo "file"
  else echo "absent"; fi
}

check() { # $1 = label, $2 = expected, $3 = actual
  if [ "$2" = "$3" ]; then
    echo "  ok   $1: $3"
  else
    echo "  FAIL $1: expected $2, got $3"
    fail=1
  fi
}

run() { out=$(cd "$1" && bash "$SYNC" 2>&1); rc=$?; }

echo "1: root AGENTS.md only -> no companion required"
d=$(mk c1); run "$d"
check "exit" 0 "$rc"
check "CLAUDE.md" absent "$(state "$d" CLAUDE.md)"

echo "2: root CLAUDE.md present -> every AGENTS.md gets a companion"
d=$(mk c2); ln -s AGENTS.md "$d/CLAUDE.md"; mkdir "$d/sub"; echo "# sub" >"$d/sub/AGENTS.md"
run "$d"
check "exit" 1 "$rc"
check "sub/CLAUDE.md" "symlink->AGENTS.md" "$(state "$d" sub/CLAUDE.md)"

echo "3: real CLAUDE.md opening with @AGENTS.md is left alone"
d=$(mk c3); printf '@AGENTS.md\n\n## Claude only\nfoo\n' >"$d/CLAUDE.md"
run "$d"
check "exit" 0 "$rc"
check "CLAUDE.md" file "$(state "$d" CLAUDE.md)"

echo "4: a copy of AGENTS.md becomes a symlink"
d=$(mk c4); cp "$d/AGENTS.md" "$d/CLAUDE.md"
run "$d"
check "exit" 1 "$rc"
check "CLAUDE.md" "symlink->AGENTS.md" "$(state "$d" CLAUDE.md)"

echo "5: a diverged CLAUDE.md is merged into AGENTS.md first"
d=$(mk c5); mkdir "$d/sub"; echo "# sub agents" >"$d/sub/AGENTS.md"
printf 'claude only rules\n' >"$d/sub/CLAUDE.md"
run "$d"
check "exit" 1 "$rc"
check "sub/CLAUDE.md" "symlink->AGENTS.md" "$(state "$d" sub/CLAUDE.md)"
check "merged" 1 "$(grep -c 'claude only rules' "$d/sub/AGENTS.md")"
check "REVIEW line" 1 "$(printf '%s\n' "$out" | grep -c '^REVIEW:')"

rm -rf "$ROOT"
[ "$fail" = 0 ] && echo "all cases passed" || echo "failures above"
exit "$fail"
