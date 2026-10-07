{ pkgs, pkgs-unstable, ... }:

let
  vscode-opentofu = pkgs.callPackage ../../../../pkgs/vscode-opentofu { };
in
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      # Versions from Nix only (updated with flake.lock): VS Code's own updates install Marketplace copies beside them
      # and mark them obsolete, and the copies are lost whenever this list changes (home-manager then has VS Code
      # rebuild its extensions.json), dropping those extensions.
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        pkgs-unstable.vscode-extensions.jnoortheen.nix-ide # Follows nixd/nixfmt closely
        ms-python.python
        ms-azuretools.vscode-docker
        pkgs-unstable.vscode-extensions.anthropic.claude-code # Moves fast, as its CLI (modules/home/programs/coding-agents)
        vscode-opentofu # Not in nixpkgs: pkgs/vscode-opentofu
      ];
      userSettings = {
        # Editor
        "editor.formatOnSave" = true;
        "editor.tabSize" = 4;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.bracketPairColorization.enabled" = true;
        "editor.rulers" = [
          80
          120
        ];

        # Files
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.autoSave" = "onFocusChange";

        # Terminal
        "terminal.integrated.defaultProfile.linux" = "zsh";

        # Workbench
        "workbench.startupEditor" = "none";

        # Extensions: installed from Nix (above), no updates (enableExtensionUpdateCheck above) nor recommendations
        "extensions.autoUpdate" = false;
        "extensions.ignoreRecommendations" = true;

        # Git
        "git.autofetch" = true;
        "git.confirmSync" = false;

        # Telemetry
        "telemetry.telemetryLevel" = "off";

        # Nix
        "nix.formatterPath" = "nixfmt";
      };

      # Terminal copy and paste: Ctrl+Shift+C copies only with a selection and the terminal focused, Ctrl+Shift+V
      # pastes only with the terminal focused.
      keybindings = [
        # Otherwise, Ctrl+Shift+C opened an external terminal (Konsole)
        {
          key = "ctrl+shift+c";
          command = "-workbench.action.terminal.openNativeConsole";
        }
        # Ctrl+V pastes in the terminal too (as on Windows and macOS): the shell no longer gets it (zsh: quoted-insert)
        {
          key = "ctrl+v";
          command = "workbench.action.terminal.paste";
          when = "terminalFocus";
        }
      ];
    };
  };
}
