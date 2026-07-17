{ inputs, ... }:
{
  imports = [
    inputs.templates.devenvModules.claude-md-sync-hooks
  ];

  enterShell = ''
    echo "Test project for claude-md-sync-hooks module"
    echo "Running syncClaudeMd script..."
    syncClaudeMd
  '';
}
