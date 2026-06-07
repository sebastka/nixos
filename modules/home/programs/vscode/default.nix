{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        ms-python.python
        ms-azuretools.vscode-docker
        anthropic.claude-code
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

        # Git
        "git.autofetch" = true;
        "git.confirmSync" = false;

        # Telemetry
        "telemetry.telemetryLevel" = "off";

        # Nix
        "nix.formatterPath" = "nixfmt";
      };
    };
  };
}
