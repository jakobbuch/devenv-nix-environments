{ pkgs, ... }:
{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    markdownlint-cli
    marksman # LSP for Markdown
  ];

  # Helper script for previewing markdown
  scripts.md-preview.exec = "pkgs.glow $1";
}
