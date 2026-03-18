{ pkgs, ... }:
{
  # https://devenv.sh/languages/
  languages.texlive = {
    enable = true;
    base = pkgs.texlive.combined.scheme-full;
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    pandoc
    librsvg
    zlib
  ];
}
