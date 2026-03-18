_: {
  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    markdownlint = {
      enable = true;
      settings.configuration = {
        default = true;
        MD013 = false; # Line length rule disable
      };
    };
  };
}
