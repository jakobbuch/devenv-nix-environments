# CLAUDE.md Sync Hooks Test

`devenv.nix` here imports the `claude-md-sync-hooks` module, so `devenv shell`
installs the `claude-md-sync` pre-commit hook and the `syncClaudeMd` script.

`./test-sync.sh` checks the rules themselves against throwaway git repos in
`/tmp` (no devenv shell needed); pass a path to test a different copy of
`scripts/sync-claude-md.sh`:

1. root `AGENTS.md` only, no root `CLAUDE.md`: nothing is created, exit 0
2. root `CLAUDE.md` present: every `AGENTS.md` gets a symlink companion
3. a real `CLAUDE.md` opening with `@AGENTS.md` is left alone
4. a `CLAUDE.md` that merely copies `AGENTS.md` becomes a symlink
5. a diverged `CLAUDE.md` is appended to `AGENTS.md`, replaced by a symlink,
   and flagged with a `REVIEW:` line

Any repair exits non-zero so the author re-stages and reviews.
