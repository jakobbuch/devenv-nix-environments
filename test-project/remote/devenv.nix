{ inputs, ... }:
{
  imports = [
    inputs.templates.devenvModules.python
    inputs.templates.devenvModules.nix
    inputs.templates.devenvModules.git-hooks
  ];

  enterShell = ''
    echo "Test project shell started"
    echo "Testing uv accessibility:"
    uv --version
    echo "Testing nixfmt accessibility:"
    nixfmt --version
  '';
}
