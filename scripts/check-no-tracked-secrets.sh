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

# Credential shapes: GitHub tokens, OpenAI-style keys, Slack tokens, AWS key ids, JWTs.
readonly TOKEN_RE='(gh[opsu]_[A-Za-z0-9]{16,}|github_pat_[A-Za-z0-9_]{20,}|\bsk-[A-Za-z0-9_-]{20,}|xox[bap]-[A-Za-z0-9-]{10,}|AKIA[0-9A-Z]{16}|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.)'
# Long values under a credential-ish key, e.g. "api_key": "....".
readonly KEYED_RE='"(api[-_]?key|apikey|token|secret|password|access_token|refresh_token)"[[:space:]]*:[[:space:]]*"[^"]{16,}"'
# key = "...", KEY=..., "x-api-key": "..." with a 20+ char value (letters+digits, no
# dots or slashes, so paths and attribute references do not match). Case-insensitive.
readonly ASSIGN_RE='[A-Za-z0-9_-]*(key|token|secret|passw(or)?d|pwd)[A-Za-z0-9_-]*["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9+_=-]{20,}["'"'"']?'
# Not a real secret: substituted at activation time from agenix, or a public SSH key blob.
readonly PLACEHOLDER_RE="${SECRETS_PLACEHOLDER_RE:-(AAAAC3[A-Za-z0-9+]{20,}|SECRET_TOKEN_[A-Z0-9_]+|PLACEHOLDER_[A-Z0-9_]+|\$\{[A-Za-z_]+\}|<[A-Za-z-]+>)}"

status=0

for file in "$@"; do
  [ -f "$file" ] || continue
  [[ $file =~ $EXCLUDE_RE ]] && continue

  # Report line numbers, but never the matched value itself. -I skips binaries.
  while IFS=: read -r lineno match; do
    [ -n "$lineno" ] || continue
    # Exempt only when the matched text itself is a placeholder, so a real
    # secret sharing a line with a placeholder is still reported.
    if printf '%s' "$match" | grep -qE "$PLACEHOLDER_RE"; then
      continue
    fi
    echo "ERROR: $file:$lineno looks like a credential (value withheld)." >&2
    status=1
  done < <(
    grep -nIEo "$TOKEN_RE|$KEYED_RE" "$file" 2>/dev/null
    # Assignments: only values that mix letters and digits count as high-entropy.
    grep -nIEio "$ASSIGN_RE" "$file" 2>/dev/null |
      grep -E ':.*[:=][[:space:]]*["'"'"']?([A-Za-z0-9+_=-]*[0-9][A-Za-z0-9+_=-]*[A-Za-z][A-Za-z0-9+_=-]*|[A-Za-z0-9+_=-]*[A-Za-z][A-Za-z0-9+_=-]*[0-9][A-Za-z0-9+_=-]*)["'"'"']?$'
  )
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
