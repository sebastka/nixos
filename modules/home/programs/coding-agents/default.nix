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
    # Claude in an editor tab ("Panel (New Tab)"; the other choice is the right sidebar). The extension also saves
    # it whenever Claude is opened elsewhere: set here, settings.json being read-only.
    "claudeCode.preferredLocation" = "panel";
    # Replaces the bundled binary's path (extension openai.chatgpt, from the marketplace)
    "chatgpt.cliExecutable" = lib.getExe config.programs.codex.package;
  };

  # CODEX_HOME = ~/.config/codex (home.preferXdgDirectories)
  programs.codex = {
    enable = true;
    package = pkgs-unstable.codex;
  };
}
