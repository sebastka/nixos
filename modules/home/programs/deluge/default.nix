{
  config,
  lib,
  pkgs,
  ...
}:

let
  ui = "${config.xdg.configHome}/deluge/gtk3ui.conf";
in
{
  # Deluge's GTK client, as a thin client only: a remote control for a Deluge daemon (deluged), never one of its own
  # (classic mode, its default). Its connections (host, port, user, password) are added in its Connection Manager:
  # ~/.config/deluge/hostlist.conf, the user's.
  home.packages = [ pkgs.deluge-gtk ];

  # Classic mode off (Preferences > Interface): only this key, at each switch. Deluge writes the rest of the file
  # itself (window size, columns...), so it can't be a read-only file from the store. Its format: a header object, then
  # the settings object (missing keys: Deluge's defaults).
  home.activation.delugeThinClient = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ui=${lib.escapeShellArg ui}
    if [ -s "$ui" ]; then
      new="$(${lib.getExe pkgs.jq} -s '.[0], (.[1] + {standalone: false})' "$ui" 2>/dev/null)" \
        || new='{"file": 1, "format": 1}{"standalone": false}' # Unreadable: started over
    else
      new='{"file": 1, "format": 1}{"standalone": false}'
    fi
    run mkdir -p "$(dirname "$ui")"
    run ${pkgs.coreutils}/bin/install -m 600 /dev/stdin "$ui" <<< "$new"
  '';
}
