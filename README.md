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

```bash
cd test-project/remote
devenv shell
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)
file for details.

```bash
cd test-project/remote
devenv shell
```
