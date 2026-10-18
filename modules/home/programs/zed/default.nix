{ pkgs-unstable, ... }:

{
  # Zed (zeditor): weekly releases (stable lags months behind), from cache.nixos.org
  programs.zed-editor = {
    enable = true;
    package = pkgs-unstable.zed-editor;

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
    };
  };
}
