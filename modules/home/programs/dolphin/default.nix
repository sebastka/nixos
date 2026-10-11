{
  config,
  lib,
  pkgs,
  ...
}:

let
  # The view of every folder (Dolphin's default: one for all of them), also the default of folders with their own
  globalViewProperties = "${config.xdg.dataHome}/dolphin/view_properties/global/.directory";
in
{
  # Dolphin: folders in Details view, with 22 px icons (32 px by default: its preview size, used for every item while
  # previews are shown; its icon size, 16 px, only without previews). Only these keys, at each switch: Dolphin writes
  # the rest of these files itself (sorting, columns, hidden files...), so they can't be read-only files from the store.
  home.activation.dolphinDetailsView = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ${lib.escapeShellArg globalViewProperties} \
      --group Dolphin --key ViewMode 1
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ${lib.escapeShellArg "${config.xdg.configHome}/dolphinrc"} \
      --group DetailsMode --key PreviewSize 22
  '';
}
