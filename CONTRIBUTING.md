# Contributing

Thank you for considering contributing to the Devenv Nix Environments!

## Development Principles

- **Nix Flake Integration**: Modules are exported via `devenvModules` in `flake.nix`.
- **Modularity**: Keep modules focused on a single language or toolset.
- **Generic Environments**: Avoid hardcoding personal paths. Use environment
  variables or relative paths where possible.
- **Devenv Standards**: Follow [devenv.sh](https://devenv.sh) conventions.

## Adding a New Module

1. Define the module in `devenv/<name>-dev.nix`.
2. Export it in `flake.nix` under `devenvModules`.
3. Add relevant git hooks in a corresponding `-hooks-dev.nix` file if applicable.
4. Test the module by importing it into the root `devenv.nix` or using the
   `test-project/` directory. For automated tests, run `./tests/run_tests.sh`.

## Style Guide

- Use `nixpkgs-fmt` for Nix files.
- Follow Markdownlint rules for documentation.
- Keep descriptions clear and concise.

## Workflow

1. Fork the repository.
2. Create a feature branch.
3. Commit your changes following [Conventional Commits](https://www.conventionalcommits.org/).
4. For releases, we use `git-cliff` to automatically generate the
   `CHANGELOG.md` based on commit messages.
5. Push to your branch and open a Pull Request.
