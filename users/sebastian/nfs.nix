# sebastian on desktops: file's NFS shares (hosts/file/nfs.nix) in ~/NFS. NixOS module (imported by ./desktop.nix).
{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  server = "file.home.karlsen.fr";
  root = "/home/sebastian/NFS"; # Not users.users.sebastian.home: NFS support needs rpcbind's user (infinite recursion)
  shares = [
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Torrent"
    "Videos"
    "homelab/k8s" # The cluster's volumes (no_root_squash: root here is root there)
  ];
  mountUnit = share: "${utils.escapeSystemdPath "${root}/${share}"}.mount";

  # A desktop notification to sebastian, when logged in: notify <summary> <body>
  notify = pkgs.writeShellApplication {
    name = "nfs-notify";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.util-linux # runuser
      pkgs.libnotify # notify-send
    ];
    text = ''
      bus="/run/user/$(id -u sebastian)/bus"
      [ -S "$bus" ] || exit 0
      runuser -u sebastian -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
        notify-send --app-name=NFS --icon=folder-remote --urgency=critical "$1" "$2"
    '';
  };
in

{
  config = lib.mkIf config.services.graphical-desktop.enable {
    # Mounted on first access (a terminal, a file manager), unmounted after 10 idle minutes. Exported to the LAN only:
    # elsewhere, an access fails within 5 s (a single attempt, no retries) instead of hanging, with a notification
    # (below). In GVfs file managers' sidebar (Nemo, Nautilus) as "NFS/<share>", with a remote folder icon: not to be
    # mistaken for the local ~/Documents... (x-gvfs-name is URL-encoded)
    fileSystems = lib.listToAttrs (
      map (
        share:
        lib.nameValuePair "${root}/${share}" {
          device = "${server}:/mnt/nfs/${share}";
          fsType = "nfs";
          options = [
            "nfsvers=4.2"
            "noauto"
            "x-systemd.automount"
            "x-systemd.idle-timeout=10min"
            "x-systemd.mount-timeout=5s"
            "retry=0"
            "_netdev"
            "x-gvfs-show"
            "x-gvfs-name=NFS%2F${lib.replaceStrings [ "/" ] [ "%2F" ] share}"
            "x-gvfs-icon=folder-remote"
          ];
        }
      ) shares
    );

    # A failed mount (unreachable server...) notifies, once a minute at most per share: also when a background
    # program triggered it
    systemd.units = lib.listToAttrs (
      map (
        share:
        lib.nameValuePair (mountUnit share) {
          overrideStrategy = "asDropin"; # The unit itself comes from /etc/fstab (systemd-fstab-generator)
          text = ''
            [Unit]
            OnFailure=nfs-mount-failed@%n.service
          '';
        }
      ) shares
    );
    systemd.services."nfs-mount-failed@" = {
      description = "Notify that %i failed";
      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 1;
      };
      serviceConfig.Type = "oneshot";
      scriptArgs = "%i";
      script = ''
        share="NFS/$(systemd-escape --unescape --path "''${1%.mount}" | sed 's|^${root}/||')"
        ${lib.getExe notify} "$share: not mounted" "${server} unreachable? journalctl -u $1"
      '';
    };

    # Mounted shares wait for the server as long as it takes (hard: no lost writes), through file's own reboots. When
    # a connection goes down and the server is unreachable (the laptop left home, the cable is out...), they're
    # unmounted, by force when busy: programs waiting on them get an error instead of hanging. The next access mounts
    # them again (automount).
    networking.networkmanager.dispatcherScripts = [
      {
        source = lib.getExe (
          pkgs.writeShellApplication {
            name = "nfs-unmount-unreachable";
            runtimeInputs = [
              pkgs.bash # /dev/tcp
              pkgs.coreutils
              pkgs.gnugrep
              pkgs.util-linux # findmnt, umount
            ];
            text = ''
              case "$2" in
                down | vpn-down) ;;
                *) exit 0 ;;
              esac
              mounts="$(findmnt --list --noheadings --types nfs4 --output TARGET | grep '^${root}/' || true)"
              [ -n "$mounts" ] || exit 0
              # Reachable through another connection (wired and Wi-Fi...): nothing to do
              if timeout 2 bash -c '</dev/tcp/${server}/2049' 2>/dev/null; then
                exit 0
              fi
              # Deepest first (homelab/k8s under homelab)
              echo "$mounts" | sort -r | while read -r mount; do
                umount "$mount" 2>/dev/null || umount --force --lazy "$mount"
              done
              ${lib.getExe notify} "NFS shares unmounted" "${server} unreachable since $1 went down"
            '';
          }
        );
      }
    ];
  };
}
