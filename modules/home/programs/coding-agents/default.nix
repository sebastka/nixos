{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  # From nixpkgs-unstable: both move fast. Updated with flake.lock (no self-update).
  programs.claude-code = {
    enable = true;
    package = pkgs-unstable.claude-code;
    configDir = "${config.xdg.configHome}/claude"; # Exports CLAUDE_CONFIG_DIR
  };

  # The VS Code extensions run our CLIs instead of their bundled binaries
  programs.vscode.profiles.default.userSettings = lib.mkIf config.programs.vscode.enable {
    # Called with the bundled binary's path first: drop it
    "claudeCode.claudeProcessWrapper" =
      (pkgs.writeShellScript "claude-vscode" ''
        shift
        exec ${lib.getExe config.programs.claude-code.finalPackage} "$@"
      '').outPath;
    # Replaces the bundled binary's path (extension openai.chatgpt, from the marketplace)
    "chatgpt.cliExecutable" = lib.getExe config.programs.codex.package;
  };

  # CODEX_HOME = ~/.config/codex (home.preferXdgDirectories)
  programs.codex = {
    enable = true;
    package = pkgs-unstable.codex;
  };
}
