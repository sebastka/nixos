{
  config,
  lib,
  pkgs,
  ...
}:

# Web apps: Chromium app windows (no browser UI), each with its own profile (logins, cookies) in
# ~/.config/chromium-apps/<profile>, listed in the application menu.
#
#   programs.webApps.apps.zoom = {
#     name = "Zoom";
#     url = "https://zoom.us";
#     icon = ./zoom.svg;
#   };
let
  cfg = config.programs.webApps;

  # Wayland app_id Chromium gives the window: chrome-<host>_<path, / as _>-<profile directory>, query and fragment
  # dropped (--class is ignored on Wayland). Used as the desktop file's name, so the compositor (KWin) and the task
  # manager match the window to its entry: its icon (task manager and title bar) instead of the generic one, grouped
  # under a pinned launcher. The profile directory makes it unique for apps sharing a URL.
  appId =
    app:
    let
      parts = builtins.match "https://([^/?#]+)(/[^?#]*)?.*" app.url;
      path = if builtins.elemAt parts 1 == null then "/" else builtins.elemAt parts 1;
    in
    "chrome-${builtins.elemAt parts 0}_${lib.replaceStrings [ "/" ] [ "_" ] path}-${app.profile}";

  appModule =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Name in the application menu.";
        };
        url = lib.mkOption {
          type = lib.types.strMatching "https://.+";
          description = "Page opened in the app window.";
        };
        profile = lib.mkOption {
          type = lib.types.strMatching "[A-Za-z0-9._-]+";
          default = name;
          description = "Chromium profile (logins, cookies), in ~/.config/chromium-apps/<profile>.";
        };
        icon = lib.mkOption {
          type = with lib.types; either path str;
          description = "Icon: a file, or an icon theme name.";
        };
        genericName = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
        };
        comment = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
        };
      };
    };
in
{
  options.programs.webApps = {
    package = lib.mkPackageOption pkgs "chromium" { };
    apps = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule appModule);
      default = { };
      description = "Web apps, by identifier (the default profile).";
    };
  };

  config = lib.mkIf (cfg.apps != { }) {
    xdg.desktopEntries = lib.mapAttrs' (
      _: app:
      lib.nameValuePair (appId app) {
        inherit (app) name genericName comment;
        icon = "${app.icon}";
        # Quoted: `#` is reserved in Exec (desktop entry specification)
        exec = ''${lib.getExe cfg.package} "--app=${app.url}" --new-window --user-data-dir=${config.xdg.configHome}/chromium-apps/${app.profile} --profile-directory=${app.profile}'';
        terminal = false;
        startupNotify = true;
      }
    ) cfg.apps;
  };
}
