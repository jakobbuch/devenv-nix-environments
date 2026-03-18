_: {
  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    nil.enable = true;
    statix.enable = true;
    statix.settings.ignore = [ ".devenv" ];
    nixfmt.enable = true;
  };
}
