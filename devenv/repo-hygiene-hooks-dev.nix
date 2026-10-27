{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.repoHygiene;

  # Each script reads its settings from environment variables (documented in the
  # script header); the wrapper pins them from the module options. The logic
  # lives in scripts/check-*.sh so the scripts also work standalone.
  mkCheck =
    name: env: script:
    pkgs.writeShellScriptBin name ''
      export PATH=${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.gawk
          pkgs.git
          pkgs.jq
        ]
      }:"$PATH"
      ${lib.concatStrings (lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}\n") env)}
      ${builtins.readFile script}
    '';

  secretsCheck = mkCheck "check-no-tracked-secrets" {
    SECRETS_PLACEHOLDER_RE = cfg.noTrackedSecrets.placeholderRegex;
    SECRETS_EXCLUDE_RE = cfg.noTrackedSecrets.excludeRegex;
  } ../scripts/check-no-tracked-secrets.sh;

  kernelCheck = mkCheck "check-kernel-device-names" {
    KERNEL_NAMES_EXCLUDE_RE = cfg.kernelDeviceNames.excludeRegex;
  } ../scripts/check-kernel-device-names.sh;

  gotchasCheck = mkCheck "check-nix-gotchas" {
    GOTCHAS_FLAKE_PATH = if cfg.nixGotchas.flakePathChecks then "1" else "0";
    GOTCHAS_STATE_VERSION = if cfg.nixGotchas.stateVersionInHostsOnly then "1" else "0";
  } ../scripts/check-nix-gotchas.sh;

  permissionsCheck = mkCheck "check-claude-permissions" {
    CLAUDE_SETTINGS_FILES = lib.concatStringsSep " " cfg.claudePermissions.settingsFiles;
  } ../scripts/check-claude-permissions.sh;
in
{
  options.repoHygiene = {
    noTrackedSecrets = {
      enable = lib.mkEnableOption "the no-tracked-secrets hook (block credentials in tracked text files)";
      placeholderRegex = lib.mkOption {
        type = lib.types.str;
        default = "(AAAAC3[A-Za-z0-9+]{20,}|SECRET_TOKEN_[A-Z0-9_]+|PLACEHOLDER_[A-Z0-9_]+|\\$\\{[A-Za-z_]+\\}|<[A-Za-z-]+>)";
        description = "ERE for values that are not secrets (placeholders, public key blobs); a match exempts the finding.";
      };
      excludeRegex = lib.mkOption {
        type = lib.types.str;
        default = "^$";
        description = "ERE for repo-relative paths never checked (e.g. encrypted files). The default matches nothing.";
      };
    };

    kernelDeviceNames = {
      enable = lib.mkEnableOption "the kernel-device-names hook (name drives by /dev/disk/by-id, not nvmeXnY or /dev/sdX)";
      files = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Regex (prek `files`) restricting the hook to matching paths; empty means every text file.";
      };
      excludeRegex = lib.mkOption {
        type = lib.types.str;
        default = "^$";
        description = "ERE for repo-relative paths never checked (changelogs, research notes). The default matches nothing.";
      };
    };

    nixGotchas = {
      enable = lib.mkEnableOption "the nix-gotchas hook (writeShellScriptBin without /bin/<name>, comment inside a `\\` continuation)";
      flakePathChecks = lib.mkEnableOption "the flake-path checks (self.outPath and hardcoded /home/<user>/.config/nixos in .nix)";
      stateVersionInHostsOnly = lib.mkEnableOption "the check that stateVersion is assigned only under hosts/";
    };

    claudePermissions = {
      enable = lib.mkEnableOption "the claude-permissions hook (no wildcard before the command tail in permissions.allow Bash rules)";
      settingsFiles = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ".claude/settings.json" ];
        description = "Repo-relative paths of the Claude settings.json files to check (no spaces in paths).";
      };
    };
  };

  # https://devenv.sh/git-hooks/
  config.git-hooks.hooks = {
    no-tracked-secrets = lib.mkIf cfg.noTrackedSecrets.enable {
      enable = true;
      description = "Block credentials in tracked text files";
      entry = "${secretsCheck}/bin/check-no-tracked-secrets";
      language = "system";
      types = [ "text" ];
      stages = [ "pre-commit" ];
      pass_filenames = true;
    };

    kernel-device-names = lib.mkIf cfg.kernelDeviceNames.enable {
      enable = true;
      description = "Name drives by /dev/disk/by-id or model, not nvmeXnY or /dev/sdX";
      entry = "${kernelCheck}/bin/check-kernel-device-names";
      language = "system";
      types = [ "text" ];
      files = cfg.kernelDeviceNames.files;
      pass_filenames = true;
    };

    nix-gotchas = lib.mkIf cfg.nixGotchas.enable {
      enable = true;
      description = "Block known Nix/shell gotchas";
      entry = "${gotchasCheck}/bin/check-nix-gotchas";
      language = "system";
      files = "\\.(nix|sh)$";
      stages = [ "pre-commit" ];
      pass_filenames = true;
    };

    claude-permissions = lib.mkIf cfg.claudePermissions.enable {
      enable = true;
      description = "claude: no wildcard before the command tail in permissions.allow Bash rules";
      entry = "${permissionsCheck}/bin/check-claude-permissions";
      language = "system";
      files = "^(${lib.concatMapStringsSep "|" lib.escapeRegex cfg.claudePermissions.settingsFiles})$";
      stages = [ "pre-commit" ];
      pass_filenames = false;
    };
  };
}
