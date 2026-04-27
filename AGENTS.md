# GitHub Copilot Instructions for Devenv Nix Environments

## Context

This repository contains reusable `devenv` shell modules exported as Nix Flake outputs. These modules are intended to be imported into other projects to provide standardized development environments for Python, LaTeX, Nix, and more.

## Development Principles

- **Nix Flake Integration**: Modules are exported via `devenvModules` in `flake.nix`.
- **Modularity**: Keep modules focused on a single language or toolset.
- **Generic Environments**: Avoid hardcoding personal paths (like `/home/user`) or personal secrets. Use environment variables or relative paths where possible.
- **Devenv Standards**: Follow [devenv.sh](https://devenv.sh) conventions for `packages`, `languages`, `scripts`, and `enterShell`.

## Language Specifics

- **Python**: Use `uv` for virtual environment and package management. Prefer `uv run` over direct script execution.
- **Nix**: Use `nixpkgs-fmt` for formatting. Prefer `pkgs` from the environment's `nixpkgs` input.
- **Markdown**: Use `markdownlint` and `shellcheck` for hooks.
- **Versioning & Changelog**: This project uses `git-cliff` for automated changelog generation and versioning.
  - Follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, etc.).
  - Use `git-cliff -o CHANGELOG.md` to update the changelog before a release.
  - Proactively suggest a new version bump when a meaningful set of changes (e.g., several `feat` or `fix` commits) has accumulated since the last tag.
  - Before suggesting a bump, run extensive tests by verifying the environments (e.g., using `test-project/` or running scripts in the modules).
  - Assist the user in drafting commit messages that match the project's grouping in `cliff.toml`.

## Git & Pre-commit Hooks

- **NEVER** use `git commit --no-verify` - hooks are mandatory
- **NEVER** use `git reset --hard` - use `git restore` instead
- **NEVER** use `git stash` on changes you want to keep - commit first instead
- If hooks modify files (formatters), add changes with `git add -A` and commit again
- If pre-commit returns exit code 1 despite passing checks (migration mode bug):

  ```bash
  rm .git/hooks/pre-commit
  devenv shell <<< 'prek install --overwrite'
  ```

- After committing, always verify: `git log --oneline -1` and `git status`
- Recovery: `git restore --staged <file>` to unstage, then re-commit properly

## Best Practices for Adding Modules

1. Define the module in `devenv/<name>-dev.nix`.
2. Export it in `flake.nix` under `devenvModules`.
3. Add relevant git hooks in a corresponding `-hooks-dev.nix` file if it provides significant value.
4. Test the module by importing it into the root `devenv.nix` for local verification.
