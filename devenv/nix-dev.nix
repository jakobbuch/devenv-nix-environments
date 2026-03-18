{ pkgs, ... }:
{
  # https://devenv.sh/languages/
  languages.nix.enable = true;

  # https://devenv.sh/packages/
  packages = with pkgs; [
    nil
    nixfmt-rfc-style
    statix
    git
    gh
    home-manager
    git-cliff
  ];

  # Common scripts for nix dev
  scripts.nix-check.exec = "nix-instantiate --parse --quiet $1 > /dev/null";
}
