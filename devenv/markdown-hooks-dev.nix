_: {
  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    markdownlint = {
      enable = true;
      args = [ "--fix" ];
      settings.configuration = {
        default = true;
        MD013 = false; # Line length rule disable
        MD036 = false; # Emphasis used instead of a header
      };
    };
  };
}
