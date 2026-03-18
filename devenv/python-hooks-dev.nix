_: {
  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    ruff-format.enable = true;
    ruff.enable = true;
    # Custom type checker hook
    ty = {
      enable = true;
      name = "ty";
      entry = "uv run ty check";
      files = "\\.py$";
      pass_filenames = false;
    };
  };
}
