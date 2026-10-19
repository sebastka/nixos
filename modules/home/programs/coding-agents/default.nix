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

  # Zed's Agent Panel: Claude Code through the ACP adapter from Nix (unfree, as its SDK: built by our CI, from the
  # Attic cache), running our CLI instead of the SDK's bundled binary. Our config directory, so the same login,
  # settings, CLAUDE.md and sessions as the CLI (Zed imports them in its history).
  programs.zed-editor.userSettings.agent_servers = lib.mkIf config.programs.zed-editor.enable {
    "Claude Code" = {
      type = "custom";
      command = lib.getExe pkgs-unstable.claude-agent-acp;
      env = {
        CLAUDE_CODE_EXECUTABLE = lib.getExe config.programs.claude-code.finalPackage;
        CLAUDE_CONFIG_DIR = config.programs.claude-code.configDir;
      };
      # New threads: edits accepted without asking (commands still ask), with Opus
      default_config_options = {
        mode = "acceptEdits";
        model = "opus";
      };
    };
    # Our Copilot CLI too (ACP: --acp), instead of the registry's (npx, ~/.copilot): the same config directory, so the
    # same login, as in a terminal
    "GitHub Copilot" = {
      type = "custom";
      command = lib.getExe config.programs.github-copilot-cli.package;
      args = [ "--acp" ];
      env = {
        COPILOT_HOME = config.programs.github-copilot-cli.configDir;
        COPILOT_AUTO_UPDATE = "false";
      };
    };
  };

  # CODEX_HOME = ~/.config/codex (home.preferXdgDirectories)
  programs.codex = {
    enable = true;
    package = pkgs-unstable.codex;
  };

  # COPILOT_HOME = ~/.config/copilot (home.preferXdgDirectories), instead of ~/.copilot. Its self-update is off: it
  # would download newer releases into COPILOT_HOME/pkg, and run them instead of ours.
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs-unstable.github-copilot-cli;
  };
  home.sessionVariables.COPILOT_AUTO_UPDATE = "false";
}
