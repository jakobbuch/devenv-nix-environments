#!/usr/bin/env bash
# Enforce the AGENTS.md "Known Gotchas" that grep can catch (2026-10-16 retro):
#   1. writeShellScriptBin interpolated without /bin/<name> (a store directory)
#   2. stateVersion assigned outside hosts/   (only with GOTCHAS_STATE_VERSION=1)
#   3. self.outPath in .nix                   (only with GOTCHAS_FLAKE_PATH=1)
#   4. a hardcoded /home/<user>/.config/nixos path in .nix (only with GOTCHAS_FLAKE_PATH=1)
#   5. a `#` comment line right after a line ending in `\` (breaks the command)
#   6. a hardcoded WAYLAND_DISPLAY=wayland-<n> (the socket number differs per session)
# Checks 1, 5 and 6 always run; 2-4 are specific to one flake layout and default off.
# Deliberate exception: put `gotcha-ok: <reason>` in a comment on the flagged line.
# Usage: check-nix-gotchas.sh FILE... | check-nix-gotchas.sh --all (every tracked file)
#        check-nix-gotchas.sh --self-test (fixtures for the rules; exits 1 on any mismatch)
# shellcheck disable=SC2016 # --self-test fixtures are literal Nix text, single quotes on purpose
set -uo pipefail
# Only these paths are checked by --all (what the hook's `files` selects).
readonly INCLUDE_RE='\.(nix|sh)$'

# --self-test: each case is a one-line .nix fixture after a writeShellScriptBin binding "shim".
if [ "${1:-}" = --self-test ] && [ "$#" -eq 1 ]; then
  dir=$(mktemp -d) || exit 2
  trap 'rm -rf "$dir"' EXIT
  fails=0
  # expect <ok|flag> <label> <nix line>
  expect() {
    local want=$1 label=$2 line=$3 rc
    printf '%s\n' '  shim = pkgs.writeShellScriptBin "shim" "echo hi";' "$line" > "$dir/case.nix"
    "$0" "$dir/case.nix" > /dev/null 2>&1
    rc=$?
    if { [ "$want" = ok ] && [ "$rc" -ne 0 ]; } || { [ "$want" = flag ] && [ "$rc" -ne 1 ]; }; then
      echo "FAIL $label: want $want, exit $rc"
      fails=$((fails + 1))
    else
      echo "ok   $label"
    fi
  }
  expect ok 'PATH entry is the bin dir' '  env = "PATH=${shim}/bin:/run/current-system/sw/bin";'
  expect ok 'exec with /bin/<name>' '  ExecStart = "${shim}/bin/shim";'
  expect flag 'bare exec of store dir' '  ExecStart = "${shim}";'
  expect flag 'PATH entry without /bin' '  env = "PATH=${shim}:$PATH";'
  expect flag '/bin prefix of another name' '  ExecStart = "${shim}/binx";'
  expect flag 'inline bare writeShellScriptBin' '  x = "${pkgs.writeShellScriptBin "x" "echo hi"}";'
  if [ "$fails" -eq 0 ]; then
    echo "self-test PASSED ($fails failures)"
  else
    echo "self-test FAILED ($fails failures)"
    exit 1
  fi
  exit 0
fi

# --all: check every tracked file (the hook runs this when the script itself changes).
if [ "${1:-}" = --all ] && [ "$#" -eq 1 ]; then
  cd "$(git rev-parse --show-toplevel)" || exit 2
  all=()
  while IFS= read -r -d '' f; do
    [ -f "$f" ] && [ ! -L "$f" ] || continue
    [[ $f =~ $INCLUDE_RE ]] || continue
    all+=("$f")
  done < <(git ls-files -z)
  set -- "${all[@]}"
fi
stateversion=${GOTCHAS_STATE_VERSION:-0}
flakepath=${GOTCHAS_FLAKE_PATH:-0}
status=0
for file in "$@"; do
  [ -f "$file" ] || continue
  case "$file" in
    *.nix) kind=nix ;;
    *.sh) kind="sh" ;;
    *) continue ;;
  esac
  out=$(awk -v f="$file" -v kind="$kind" -v sv="$stateversion" -v fp="$flakepath" '
    function flag(n, m) { print f ":" n ": " m; bad = 1 }
    { line[NR] = $0 }
    END {
      if (kind == "nix") {
        # Names bound to a writeShellScriptBin result, for the `${name}` sub-case.
        for (i = 1; i <= NR; i++)
          if (match(line[i], /^[[:space:]]*[A-Za-z_][A-Za-z0-9_-]*[[:space:]]*=[[:space:]]*(pkgs\.|final\.)?writeShellScriptBin[[:space:]]/)) {
            s = line[i]; sub(/^[[:space:]]*/, "", s); sub(/[[:space:]]*=.*/, "", s); names[s] = 1
          }
      }
      for (i = 1; i <= NR; i++) {
        l = line[i]
        ok = (l ~ /gotcha-ok:/)
        if (kind == "nix" && !ok && l !~ /^[[:space:]]*#/) {
          if (match(l, /\$\{[[:space:]]*(pkgs\.|final\.)?writeShellScriptBin[[:space:]]/)) {
            rest = substr(l, RSTART + RLENGTH)
            # shortcut: a correct multi-line interpolation ending in /bin/ is still flagged, follow the closing brace if one ever needs it.
            # Single-line interpolation: text after the closing brace must be /bin then a non-name char (/ : " ...).
            if (match(rest, /\}[^}]*$/) && substr(rest, RSTART + 1) !~ /^\/bin([^A-Za-z0-9_-]|$)/)
              flag(i, "writeShellScriptBin interpolated without /bin/<name> (it is a store directory)")
            else if (rest !~ /\}/)
              flag(i, "multi-line writeShellScriptBin interpolation; make it a let binding and use ${x}/bin/<name>")
          }
          for (n in names) {
            t = l
            while ((p = index(t, "${" n "}")) > 0) {
              if (substr(t, p + length(n) + 3) !~ /^\/bin([^A-Za-z0-9_-]|$)/)
                flag(i, "${" n "} is a writeShellScriptBin store directory; append /bin/<name>")
              t = substr(t, p + length(n) + 3)
            }
          }
          if (sv == 1 && l ~ /(^|[^A-Za-z0-9_])stateVersion[[:space:]]*=/ && f !~ /^(\.\/)?hosts\//)
            flag(i, "stateVersion belongs in hosts/ only")
          if (fp == 1 && l ~ /self\.outPath/)
            flag(i, "self.outPath changes every rebuild; flakePath is a hardcoded string")
          if (fp == 1 && l ~ /\/home\/[^ \/"]+\/\.config\/nixos/)
            flag(i, "hardcoded flake path; use flakePath from specialArgs")
        }
        if (!ok && l !~ /^[[:space:]]*#/ && l ~ /WAYLAND_DISPLAY[[:space:]]*=[[:space:]]*["\047]?wayland-[0-9]/)
          flag(i, "hardcoded WAYLAND_DISPLAY; inherit it from the session (systemd user manager) instead")
        if (!ok && i < NR && l !~ /^[[:space:]]*#/ && l ~ /\\[[:space:]]*$/ && line[i + 1] ~ /^[[:space:]]*#/)
          flag(i + 1, "comment line inside a `\\`-continued command")
      }
      exit bad
    }
  ' "$file") || { printf '%s\n' "$out"; status=1; }
done
exit "$status"
