{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  # Zed (zeditor): weekly releases (stable lags months behind), from cache.nixos.org
  programs.zed-editor = {
    enable = true;
    package = pkgs-unstable.zed-editor;

    # Extensions, from Zed's registry: installed (and updated) by Zed itself (auto_install_extensions)
    extensions = [
      "nix"
      "opentofu"
      "dockerfile" # Docker Compose too
    ];
    # In Zed's PATH: the Nix extension's language server (it downloads none, unlike Zed's other languages)
    extraPackages = [ pkgs.nixd ];

    # Merged into ~/.config/zed/settings.json at each switch, these keys winning: Zed can still save its own changes
    # (the theme picker, an agent added...), kept unless set here (mutableUserSettings, the default).
    userSettings = {
      # The agents of the Agent Panel (ACP), from Zed's registry
      agent_servers = {
        github-copilot-cli.type = "registry";
        claude-acp.type = "registry";
      };

      theme = {
        mode = "dark";
        light = "One Light";
        dark = "One Dark";
      };
      icon_theme = "Zed (Default)";
      ui_font_size = 16;
      buffer_font_size = 15;

      # The project tree on the left (Zed's default: the right)
      project_panel.dock = "left";

      # Editor, as VS Code (modules/home/programs/vscode). Already Zed's defaults: tab size 4, trailing whitespace
      # trimmed and a final newline on save, no minimap.
      format_on_save = "on";
      show_whitespaces = "boundary";
      wrap_guides = [
        80
        120
      ];
      autosave = "on_focus_change";
      colorize_brackets = true;

      # HuJSON (Tailscale's policy file...) as JSON with comments
      file_types.JSONC = [ "*.hujson" ];

      telemetry = {
        # diagnostics = false; # Crash reports
        metrics = false; # Usage data
      };

      # Nix: nixd only (completion and docs of NixOS and home-manager options), formatting with nixfmt (as VS Code)
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];
      lsp.nixd.settings.formatting.command = [ (lib.getExe pkgs.nixfmt) ];
    };
  };
}
