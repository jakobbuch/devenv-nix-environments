#!/usr/bin/env bash
# Refuse to commit credentials into the repo (all tracked text files).
#
# Why this exists: it scans every tracked text file, not only filesystem/dot/.
# Home-managed files under filesystem/dot/ are the sharpest case: Home Manager
# links them into $HOME, so applications can write straight into the worktree.
# That is deliberate (the configs stay git-tracked), but it means any app that
# stores a credential in its config file commits it on the next `git add`.
# Copilot CLI did exactly that with an OAuth token. Docs, Nix files and scripts
# can leak a pasted key the same way.
#
# Placeholder values (SECRET_TOKEN_*, PLACEHOLDER_*) are expected: activation
# scripts substitute the real secret at rebuild time. Override the pattern with
# SECRETS_PLACEHOLDER_RE (ERE).
#
# Usage: check-no-tracked-secrets.sh FILE... | check-no-tracked-secrets.sh --all (every tracked file)    (pre-commit passes staged files)
#        check-no-tracked-secrets.sh --self-test (proves each credential shape is caught and clean text is not)
set -uo pipefail
# Paths never checked (ERE, repo-relative): single source, applies to FILE... and --all.
# Override with SECRETS_EXCLUDE_RE; the default matches nothing.
readonly EXCLUDE_RE="${SECRETS_EXCLUDE_RE:-^\$}"

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

# Credential shapes: GitHub and GitLab tokens, OpenAI-style keys, Slack tokens, AWS key ids,
# JWTs, PEM private-key headers, and credential-bearing URLs (scheme://user:password@host).
readonly TOKEN_RE='(gh[opsu]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{20,}|\bsk-[A-Za-z0-9_-]{20,}|xox[bap]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.|glpat-[A-Za-z0-9_-]{20,}|-{5}BEGIN ([A-Z0-9]+ )*PRIVATE KEY-{5}|://[^/[:space:]:@]+:[^/[:space:]@]+@)'
# Credential-bearing URL whose password is a placeholder word or a shell/template reference.
# Kept apart from PLACEHOLDER_RE so a module-supplied placeholderRegex cannot drop it.
# shortcut: the placeholder words are a fixed list (pass, password, secret), upgrade when a real dummy word gets flagged
readonly URL_PLACEHOLDER_RE='://[^/[:space:]:@]+:(pass|password|secret|PASSWORD|SECRET|[$][{]?[A-Za-z_]+[}]?)@'
# Long values under a credential-ish key, e.g. "api_key": "....".
readonly KEYED_RE='"(api[-_]?key|apikey|token|secret|password|access_token|refresh_token)"[[:space:]]*:[[:space:]]*"[^"]{16,}"'
# key = "...", KEY=..., "x-api-key": "..." with a 20+ char value (letters+digits, no
# dots or slashes, so paths and attribute references do not match). Case-insensitive.
readonly ASSIGN_RE='[A-Za-z0-9_-]*(key|token|secret|passw(or)?d|pwd)[A-Za-z0-9_-]*["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9+_=-]{20,}["'"'"']?'
# Not a real secret: substituted at activation time from agenix, or a public SSH key blob.
# The default is single-quoted: a `}` inside a ${VAR:-...} default closes the expansion early.
readonly PLACEHOLDER_DEFAULT_RE='(AAAAC3[A-Za-z0-9+]{20,}|SECRET_TOKEN_[A-Z0-9_]+|PLACEHOLDER_[A-Z0-9_]+|\$\{[A-Za-z_]+\}|<[A-Za-z-]+>)'
readonly PLACEHOLDER_RE="${SECRETS_PLACEHOLDER_RE:-$PLACEHOLDER_DEFAULT_RE}"

# scan_file FILE: prints file:line for each credential-shaped match, never the value.
# Returns 1 if any match was not an exempt placeholder, else 0.
scan_file() {
  local file="$1" lineno match bad=0
  # Report line numbers, but never the matched value itself. -I skips binaries.
  while IFS=: read -r lineno match; do
    [ -n "$lineno" ] || continue
    # Exempt only when the matched text itself is a placeholder, so a real
    # secret sharing a line with a placeholder is still reported.
    if printf '%s' "$match" | grep -qE "$PLACEHOLDER_RE"; then
      continue
    fi
    if printf '%s' "$match" | grep -qE "$URL_PLACEHOLDER_RE"; then
      continue
    fi
    echo "ERROR: $file:$lineno looks like a credential (value withheld)." >&2
    bad=1
  done < <(
    grep -nIEo "$TOKEN_RE|$KEYED_RE" "$file" 2>/dev/null
    # Assignments: only values that mix letters and digits count as high-entropy.
    grep -nIEio "$ASSIGN_RE" "$file" 2>/dev/null |
      grep -E ':.*[:=][[:space:]]*["'"'"']?([A-Za-z0-9+_=-]*[0-9][A-Za-z0-9+_=-]*[A-Za-z][A-Za-z0-9+_=-]*|[A-Za-z0-9+_=-]*[A-Za-z][A-Za-z0-9+_=-]*[0-9][A-Za-z0-9+_=-]*)["'"'"']?$'
  )
  return "$bad"
}

# self_test: every credential shape must exit 1, every placeholder and clean sample exit 0.
# Samples are assembled from parts, so this file holds no complete fake credential.
self_test() {
  local dir pass=0 fail=0 name want got tok tok2 dash='-----'
  dir="$(mktemp -d)" || exit 2
  trap 'rm -rf "$dir"' EXIT
  tok='a1B2c3D4e5F6g7H8i9J0k'
  tok2='a1B2c3D4e5F6g7H8i9J0k1L2'
  printf 'Rotate the key glp%s%s now\n' 'at-' "$tok" >"$dir/gitlab-bare.txt"
  printf 'x = "glp%s%s"\n' 'at-' "$tok" >"$dir/gitlab-assign.txt"
  printf '%sBEGIN RSA PRIVATE KEY%s\n' "$dash" "$dash" >"$dir/pem-rsa.txt"
  printf '%sBEGIN PRIVATE KEY%s\n' "$dash" "$dash" >"$dir/pem-bare.txt"
  printf '%sBEGIN OPENSSH PRIVATE KEY%s\n' "$dash" "$dash" >"$dir/pem-openssh.txt"
  printf 'git clone %s%s%s\n' 'https://' 'user:Hunter2Fake99' '@host/path.git' >"$dir/url-real.txt"
  # shellcheck disable=SC2016  # the ${PASSWORD} text is the sample, not an expansion
  printf 'git clone %s%s%s\n' 'https://' 'user:${PASSWORD}' '@host/' >"$dir/url-tmpl.txt"
  printf 'git clone %s%s%s\n' 'https://' 'user:PLACEHOLDER_X' '@host/' >"$dir/url-ph.txt"
  printf 'Use the gh%s%s value\n' 'p_' "$tok2" >"$dir/gh.txt"
  printf 'nothing to see here\n' >"$dir/clean.txt"

  # expect WANT_EXIT NAME: the sample $dir/NAME must exit WANT_EXIT.
  expect() {
    want="$1" name="$2"
    scan_file "$dir/$name" 2>/dev/null
    got=$?
    if [ "$got" -eq "$want" ]; then
      pass=$((pass + 1))
    else
      fail=$((fail + 1))
      echo "FAIL: $name want exit $want got $got"
    fi
  }

  expect 1 gitlab-bare.txt
  expect 1 gitlab-assign.txt
  expect 1 pem-rsa.txt
  expect 1 pem-bare.txt
  expect 1 pem-openssh.txt
  expect 1 url-real.txt
  expect 0 url-tmpl.txt
  expect 0 url-ph.txt
  expect 1 gh.txt
  expect 0 clean.txt

  if [ "$fail" -ne 0 ]; then
    echo "self-test: $fail failed, $pass passed"
    exit 1
  fi
  echo "self-test: $pass passed"
  exit 0
}

if [ "${1:-}" = --self-test ]; then
  self_test
fi

status=0

for file in "$@"; do
  [ -f "$file" ] || continue
  [[ $file =~ $EXCLUDE_RE ]] && continue
  scan_file "$file" || status=1
done

if [ "$status" -ne 0 ]; then
  cat >&2 <<'EOF'

Refusing to commit a credential into the worktree.

Credential state does not belong in git: keep it out of tracked files, or
commit a placeholder and substitute the real value at deploy time.

If this is a false positive, widen the placeholder pattern
(SECRETS_PLACEHOLDER_RE, or the module's placeholderRegex option).
EOF
fi

exit "$status"
