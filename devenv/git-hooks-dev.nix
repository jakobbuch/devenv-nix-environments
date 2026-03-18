{
  pkgs,
  ...
}:
{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    pre-commit
    # Shell development tools
    shellcheck
    shfmt
  ];

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    # Bash/Shell hooks
    shellcheck.enable = true;
  };

  # https://devenv.sh/scripts/
  scripts = {
    # Fix git hooks
    fixHooks = {
      exec = ''
        pushd "$DEVENV_ROOT"
        echo "Updating devenv inputs..."
        devenv update nixos-config
        echo "Unsetting core.hooksPath and reinstalling hooks..."
        git config --unset core.hooksPath
        pre-commit install --overwrite
        echo "Git hooks fixed and updated!"
        popd
      '';
      description = "Update devenv inputs, unset core.hooksPath and reinstall pre-commit hooks";
    };
  };
}
