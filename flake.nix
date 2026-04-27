{
  description = "Standard development environments (devenv) for Python, LaTeX, Nix and more";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      devenv,
      ...
    }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (
            system:
            f {
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
              inherit system;
            }
          );
    in
    {
      # Export modules for other projects' devenv.nix
      devenvModules = {
        python = ./devenv/python-dev.nix;
        latex = ./devenv/latex-dev.nix;
        nix = ./devenv/nix-dev.nix;
        markdown = ./devenv/markdown-dev.nix;
        bifrost = ./devenv/bifrost-dev.nix;
        git-hooks = ./devenv/git-hooks-dev.nix;
        nix-hooks = ./devenv/nix-hooks-dev.nix;
        python-hooks = ./devenv/python-hooks-dev.nix;
        markdown-hooks = ./devenv/markdown-hooks-dev.nix;
        local-hooks = ./devenv/local-hooks-dev.nix;
      };

      devShells = forAllSystems (
        { pkgs, ... }:
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              ./devenv.nix
            ];
          };
        }
      );
    };
}
