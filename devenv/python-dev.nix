{
  pkgs,
  lib,
  config,
  ...
}:
let
  buildPackages = with pkgs; [
    graphviz-nox
    pkg-config
    stdenv.cc
    libuv
    zlib
    pandoc
    librsvg
  ];
in
{
  # https://devenv.sh/reference/options/#cachix
  cachix.enable = true;
  cachix.pull = [ "pre-commit-hooks" ];

  # https://devenv.sh/basics/
  env = {
    GREET = "devenv";
    LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath buildPackages}:${pkgs.stdenv.cc.cc.lib}/lib";
    # Add these for building C extensions
    LIBRARY_PATH = "${pkgs.lib.makeLibraryPath buildPackages}";
    CPATH = "${pkgs.lib.makeSearchPathOutput "dev" "include" buildPackages}";
  };

  # https://devenv.sh/packages/
  packages =
    with pkgs;
    [
      # define packages to be installed in the environment here
      hello
      uv
      ruff
      gnused
      util-linuxMinimal
    ]
    ++ buildPackages;

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    uv = {
      enable = true;
      sync.enable = true;
    };
    # add predefined libraries to the python environment, like c libraries for numpy, etc.
    libraries = buildPackages;
  };

  # https://devenv.sh/scripts/
  scripts = {
    helloDevenv.exec = "echo hello from $GREET";

    # Python environment management
    uvReset = {
      exec = ''
        echo "Removing old virtual environment..."
        rm -rf .venv
        rm -rf .devenv/state/venv
        echo "Creating new virtual environment with current Python..."
        uv venv
        echo "Syncing dependencies..."
        uv sync
        echo "Virtual environment recreated successfully!"
        echo "Activating Python virtual environment"
        if [ -f .devenv/state/venv/bin/activate ]; then
          source .devenv/state/venv/bin/activate
        fi
      '';
      description = "Recreate the Python virtual environment";
    };

    # Update UV manages packages
    uvUpdate = {
      exec = ''
        uv lock --upgrade
        uv sync
      '';
      description = "Update UV managed packages";
    };
  };

  enterShell = ''
    hello

    echo "Update nixpkgs with 'devenv update'."
    echo "After updating, run 'uvReset' to recreate the Python environment if python was updated."
    echo "If git hooks fail with stale paths, run 'fixHooks'."

    if [ -f .devenv/state/venv/bin/activate ]; then
      echo "Activating Python virtual environment..."
      source .devenv/state/venv/bin/activate
    else
      echo "Python virtual environment not found. Run 'uvReset' to create it."
    fi

    echo "Python environment managed by $(uv --version)"
    echo "Use 'uv run python' to execute Python scripts."
    echo "If you get interpreter path errors, run 'uvReset' to recreate the venv."
    uv --version
    uv run python --version

    echo
    echo "Helper scripts:"
    ${pkgs.gnused}/bin/sed -e 's| |••|g' -e 's|=| |' <<EOF | ${pkgs.util-linuxMinimal}/bin/column -t | ${pkgs.gnused}/bin/sed -e 's|^| |' -e 's|••| |g'
    ${lib.generators.toKeyValue { } (lib.mapAttrs (name: value: value.description) config.scripts)}
    EOF
    echo
  '';
}
