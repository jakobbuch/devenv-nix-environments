# Devenv Nix Environments

Standardized [devenv.sh](https://devenv.sh) shell modules for specialized
development environments.

## Modules

The following modules are available under the `devenvModules` output:

- **python**: Python environment using `uv` and common build libraries.
- **latex**: LaTeX development environment.
- **nix**: Nix development tools (`nil`, `nixfmt`, `statix`).
- **markdown**: Markdown editing tools.
- **bifrost**: Environment for the Bifrost project.
- **git-hooks**: Base git-hooks configuration.
- **python-hooks**: Python-specific pre-commit (prek) hooks (ruff).
- **nix-hooks**: Nix-specific pre-commit (prek) hooks (nixfmt).
- **markdown-hooks**: Markdown-specific pre-commit (prek) hooks (markdownlint).
- **local-hooks**: Auto-installs git hooks via pre-commit in local repositories (fail-safe).
- **claude-md-sync-hooks**: Keeps every AGENTS.md readable by Claude Code, which reads it natively unless a root CLAUDE.md is present.

## How to use

In your project's `devenv.yaml`, add this repository as an input. Then, import
the desired module(s) in your `devenv.nix`.

### Example `devenv.yaml`

```yaml
inputs:
  devenv-modules:
    url: github:jakobbuch/devenv-nix-environments
```

### Example `devenv.nix`

```nix
{ inputs, ... }: {
  imports = [
    inputs.devenv-modules.devenvModules.python
    inputs.devenv-modules.devenvModules.git-hooks
    inputs.devenv-modules.devenvModules.python-hooks
  ];
}
```

## Local Development

This repository includes its own `devenv.nix` that uses the `nix` and
`nix-hooks` modules for self-hosting its development tools.

To enter the development shell:

```bash
devenv shell
```

### Python Environment (`uv`)

When using the `python` module, dependencies are managed via `uv`.

- A virtual environment is automatically synced on shell entry if
  `languages.python.uv.sync.enable` is true.
- If you encounter interpreter path errors after updating Nixpkgs, run the
  `uvReset` script to recreate the virtual environment:

  ```bash
  uvReset
  ```

- To update your Python dependencies:

  ```bash
  uvUpdate
  ```

### Local Hooks (`local-hooks`)

The `local-hooks` module automatically installs git hooks via pre-commit when
entering a shell in a git repository.

**Features:**

- Auto-detects git repositories (`.git` directory)
- Only runs if `.pre-commit-config.yaml` exists
- Fail-safe: gracefully skips if `uv` or pre-commit not yet available
- Provides `installLocalHooks` script for manual installation

**Usage:**

```nix
imports = [
  inputs.devenv-modules.devenvModules.local-hooks
];
```

**Note:** For best results, combine with the `python` module which provides `uv`.
The module includes `pre-commit` as a package and will attempt to run it via
`uv run pre-commit` if available, falling back to a global installation.

## Testing

A [test-project/](test-project/) directory is provided to verify the modules.

### Local Testing

Uses the local files in this repository (useful for iterative development):

```bash
cd test-project/local
devenv shell
```

### Remote Testing

Fetches the modules from GitHub to verify the published flake:

cd test-project/remote
devenv shell

```bash

### CLAUDE.md Sync Hooks Testing

Test the `claude-md-sync-hooks` module against throwaway git repos (five cases,
no devenv shell needed):

```bash
./test-project/claude-md-sync/test-sync.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details.

```bash
cd test-project/remote
devenv shell
```

## Standalone Script

The `scripts/sync-claude-md.sh` script can be used independently of Nix/devenv:

```bash
# Copy to your project
cp scripts/sync-claude-md.sh /your/project/

# Run manually
./sync-claude-md.sh

# Or specify a different repository
./sync-claude-md.sh /path/to/repo
```

This enables Claude/OpenCode collaboration in any Git project, regardless of build system.

## CLAUDE.md Sync Module

The `claude-md-sync-hooks` module keeps `AGENTS.md` the single instruction
source for every agent. Claude Code reads `AGENTS.md` natively since 2.1.277,
but only as a fallback: a root `CLAUDE.md` (or `.claude/CLAUDE.md`) switches
that fallback off for the whole tree, and a real `CLAUDE.md` beside an
`AGENTS.md` hides it unless it is a symlink or opens with `@AGENTS.md`.

### Architecture

```text
AGENTS.md  = SOURCE FILE (read by every agent)
   ↑
   └── CLAUDE.md (only where needed: symlink → AGENTS.md,
                  or a real file opening with @AGENTS.md
                  when Claude-only rules follow the import)
```

**Key principle:** without a root `CLAUDE.md` no companion is created at all;
with one, every `AGENTS.md` gets a symlink.

### Usage

```nix
# devenv.nix
{ inputs, ... }: {
  imports = [
    inputs.devenv-modules.devenvModules.claude-md-sync-hooks
  ];
}
```

**Features:**

- Pre-commit hook checks before every commit, non-zero on any change
- Creates a `CLAUDE.md` symlink only where the repo root has a `CLAUDE.md`
- Accepts a real `CLAUDE.md` that opens with `@AGENTS.md`
- Repairs drift: a copy of `AGENTS.md` becomes a symlink, a diverged
  `CLAUDE.md` is merged into `AGENTS.md` first and flagged for review

### Usage in Non-Nix Projects

For non-Nix projects, use the standalone script:

```bash
cp scripts/sync-claude-md.sh /your/project/
./sync-claude-md.sh
```

See `test-project/claude-md-sync/README.md` for details.
