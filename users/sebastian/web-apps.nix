{ config, lib, pkgs, ... }:

# Web apps: Chromium app windows (no browser UI), each with its own profile (logins, cookies) in
# ~/.config/chromium-apps/<profile>, listed in the application menu. Desktops only (./desktop.nix).
let
  webApp =
    {
      name,
      url,
      profile,
      icon,
      genericName,
      comment,
    }:
    let
      # Wayland app_id Chromium gives the window: chrome-<host>_<path, / as _>-<profile directory>, query
      # and fragment dropped (--class is ignored on Wayland). Used as the desktop file's name, so KWin and
      # the task manager match the window to this entry: its icon (task manager and title bar) instead of
      # the generic one, grouped under a pinned launcher. The profile directory makes it unique for apps
      # sharing a URL (the bitwarden.eu accounts).
      parts = builtins.match "https://([^/?#]+)(/[^?#]*)?.*" url;
      path = if builtins.elemAt parts 1 == null then "/" else builtins.elemAt parts 1;
      appId = "chrome-${builtins.elemAt parts 0}_${lib.replaceStrings [ "/" ] [ "_" ] path}-${profile}";
    in
    lib.nameValuePair appId {
      inherit name genericName comment icon;
      # Quoted: `#` is reserved in Exec (desktop entry specification)
      exec = ''${lib.getExe pkgs.chromium} "--app=${url}" --new-window --user-data-dir=${config.xdg.configHome}/chromium-apps/${profile} --profile-directory=${profile}'';
      terminal = false;
      startupNotify = true;
    };

  bitwarden = account: url: {
    name = "Bitwarden (${account})";
    inherit url;
    icon = "${./icons/bitwarden.svg}"; # Not bitwarden-desktop's: it may not stay installed
    genericName = "Password Manager";
    comment = "Bitwarden web vault for ${account}";
  };
in
{
  xdg.desktopEntries = lib.mapAttrs' (_: webApp) {
    bitwarden-private = bitwarden "sebastian@karlsen.fr" "https://vault.bitwarden.com/#/vault" // {
      profile = "bitwarden-private-sebastian.karlsen.fr";
    };
    bitwarden-inboxcom = bitwarden "sebastian@corp.inbox.com" "https://vault.bitwarden.eu/#/vault" // {
      profile = "bitwarden-work-sebastian.corp.inbox.com";
    };
    bitwarden-inboxcom-post = bitwarden "post@corp.inbox.com" "https://vault.bitwarden.eu/#/vault" // {
      profile = "bitwarden-work-post.corp.inbox.com";
    };
    teams = {
      name = "Microsoft Teams (Work)";
      url = "https://teams.live.com/v2/";
      profile = "teams";
      icon = "${./icons/teams.svg}";
      genericName = "Meetings";
      comment = "Video Conferencing, Meetings, Calling";
    };
    zoom = {
      name = "Zoom";
      url = "https://zoom.us";
      profile = "zoom";
      icon = "${./icons/zoom.svg}"; # From the Papirus icon theme (GPL-3.0)
      genericName = "Meetings";
      comment = "Video Conferencing, Meetings, Calling";
    };
  };
}
