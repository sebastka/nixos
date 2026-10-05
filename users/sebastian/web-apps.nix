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
    {
      inherit name genericName comment icon;
      # Quoted: `#` is reserved in Exec (desktop entry specification)
      exec = ''${lib.getExe pkgs.chromium} "--app=${url}" --new-window --user-data-dir=${config.xdg.configHome}/chromium-apps/${profile}'';
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
  xdg.desktopEntries = lib.mapAttrs (_: webApp) {
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
