{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  vscode-opentofu = pkgs.callPackage ../../../../pkgs/vscode-opentofu { };
  vscode-direnv-trusted = pkgs.callPackage ../../../../pkgs/vscode-direnv-trusted { };
in
{
  programs.vscode = {
    enable = true;
    # Its shared storage (recently opened, workspace trust: state) in XDG's state directory instead of ~/.vscode-shared:
    # only this flag moves it (no variable), added to its launcher (bin/code, which the desktop entry runs)
    package = pkgs-unstable.vscode.override {
      commandLineArgs = "--shared-data-dir=${config.xdg.stateHome}/vscode/shared";
    };
    # Extensions from Nix only (updated with flake.lock): their directory (below) is a read-only store directory, with
    # its own extensions.json. A mutable one mixes VS Code's own state with them (its Marketplace updates, marking
    # ours obsolete, and an extensions.json rebuilt whenever this list changes), which broke extensions.
    mutableExtensionsDir = false;
    # ~/.vscode/argv.json (runtime arguments), read-only: no crash reporter, so no crash-reporter-id either
    argvSettings.enable-crash-reporter = false;
    profiles.default = {
      enableExtensionUpdateCheck = false; # Nothing to update (extensions.autoCheckUpdates)
      extensions = with pkgs.vscode-extensions; [
        pkgs-unstable.vscode-extensions.jnoortheen.nix-ide
        ms-python.python
        ms-azuretools.vscode-docker
        pkgs-unstable.vscode-extensions.anthropic.claude-code # Moves fast, as its CLI (modules/home/programs/coding-agents)
        vscode-opentofu # Not in nixpkgs: pkgs/vscode-opentofu
        vscode-direnv-trusted # Ours: pkgs/vscode-direnv-trusted
      ];
      userSettings = {
        # Editor
        "editor.formatOnSave" = false; # Format on demand only (Ctrl+Shift+I)
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

        # JSON with comments (jsonc): also HuJSON (Tailscale's policy file...). Trailing commas allowed in both, as
        # HuJSON does (jsonc warns about them by default).
        "files.associations"."*.hujson" = "jsonc";
        "json.schemas" = [
          {
            fileMatch = [
              "*.jsonc"
              "*.hujson"
              "*.json5"
            ];
            schema.allowTrailingCommas = true;
          }
        ];

        # Terminal
        "terminal.integrated.defaultProfile.linux" = "zsh";
        # Without the kitty keyboard protocol (on by default): with it, Shift+number on a non-US layout (Norwegian)
        # reached programs using it (Neovim) as Shift+1... instead of "!", "#"..., and typed nothing
        "terminal.integrated.enableKittyKeyboardProtocol" = false;

        # Workbench
        "workbench.startupEditor" = "none";

        # Extensions: installed from Nix (above), no updates nor recommendations
        "extensions.autoUpdate" = "off"; # No longer a boolean: VS Code rewrites false (read-only here) to "off"
        "extensions.ignoreRecommendations" = true;

        # Git
        "git.autofetch" = true;
        "git.confirmSync" = false;

        # Telemetry
        "telemetry.telemetryLevel" = "off";

        # Nix
        "nix.formatterPath" = "nixfmt";

        # direnv (direnv-trusted): the shell's, with its configuration (modules/home/programs/direnv)
        "direnv-trusted.path" = lib.getExe config.programs.direnv.package;
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

  # VS Code's extensions and its CLI's data (code tunnel...) in XDG directories, instead of ~/.vscode, which keeps only
  # argv.json (its location can't be changed, but for portable mode). The extensions directory home-manager makes
  # (always ~/.vscode/extensions), moved; VS Code finds it with VSCODE_EXTENSIONS. The variables reach the desktop's
  # apps at the next login (systemd user environment).
  home.file.".vscode/extensions".enable = lib.mkForce false;
  xdg.dataFile."vscode/extensions".source = config.home.file.".vscode/extensions".source;
  home.sessionVariables = {
    VSCODE_EXTENSIONS = "${config.xdg.dataHome}/vscode/extensions";
    VSCODE_CLI_DATA_DIR = "${config.xdg.dataHome}/vscode/cli";
  };
}
