{ inputs, ... }:
{
  imports = [
    inputs.templates.devenvModules.python
    inputs.templates.devenvModules.latex
    inputs.templates.devenvModules.nix
    inputs.templates.devenvModules.markdown
    inputs.templates.devenvModules.bifrost
    inputs.templates.devenvModules.git-hooks
    inputs.templates.devenvModules.nix-hooks
    inputs.templates.devenvModules.python-hooks
    inputs.templates.devenvModules.markdown-hooks
    inputs.templates.devenvModules.local-hooks
  ];

  enterShell = ''
    echo "Test project shell started"
    echo "Testing uv accessibility:"
    uv --version
    echo "Testing nixfmt accessibility:"
    nixfmt --version
  '';
}
