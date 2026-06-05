_: {
  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    markdownlint = {
      enable = true;
      args = [ "--fix" ];
      settings.configuration = {
        default = true;
        MD003 = false; # Header style rule disable
        MD005 = false; # Inconsistent indentation rule disable
        MD007 = false; # Unordered list indentation rule disable
        MD013 = false; # Line length rule disable
        MD029 = false; # Ordered list item prefix rule disable
        MD036 = false; # Emphasis used instead of a header
        MD041 = false; # First line in file should be a top level header
        MD050 = false; # Disable to allow both ** and __ for strong emphasis
        MD060 = false; # Consider first line of file as a header
      };
    };
  };
}
