{ impermanence, pkgs, ... }:

{
  imports = [ impermanence.nixosModules.impermanence ];

  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.systemd.storePaths = [ pkgs.coreutils ];

  # On each boot, delete @root and restore it from the empty @root-blank snapshot.
  # Runs after LUKS is unlocked and before the root filesystem is mounted.
  boot.initrd.systemd.services.rollback = {
    description = "Rollback BTRFS root subvolume to blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "cryptsetup.target" ];
    requires = [ "cryptsetup.target" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      set -euo pipefail
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ /dev/mapper/luks-9a13ab37-7df1-4b5f-8965-74feb43c1cd3 /mnt
      mkdir -p /mnt/old_roots
      timestamp=$(date +%s)
      btrfs subvolume snapshot -r /mnt/@root "/mnt/old_roots/$timestamp"
      # Delete any nested subvolumes first (e.g. /var/lib/machines created by systemd).
      # sort -r gives deepest paths first so children are deleted before parents.
      # btrfs list format: ID N gen N top level N path PATH — PATH is field 9.
      btrfs subvolume list -o /mnt/@root | sort -r | \
        while read -r _ _ _ _ _ _ _ _ sv; do
          btrfs subvolume delete "/mnt/$sv"
        done
      btrfs subvolume delete /mnt/@root
      btrfs subvolume snapshot /mnt/@root-blank /mnt/@root
      umount /mnt
    '';
  };

  systemd.services.btrfs-old-roots-cleanup = {
    description = "Delete BTRFS root snapshots older than 7 days";
    serviceConfig.Type = "oneshot";
    script = ''
      device=$(findmnt -n -o SOURCE /)
      mnt=/run/btrfs-top
      mkdir -p "$mnt"
      mount -t btrfs -o subvol=/ "$device" "$mnt"
      cutoff=$(($(date +%s) - 7 * 86400))
      for snap in "$mnt"/old_roots/*/; do
        [ -d "$snap" ] || continue
        ts=$(basename "$snap")
        if [[ "$ts" =~ ^[0-9]+$ ]] && [ "$ts" -lt "$cutoff" ]; then
          btrfs subvolume delete "$snap"
        fi
      done
      umount "$mnt"
    '';
  };

  systemd.timers.btrfs-old-roots-cleanup = {
    description = "Daily cleanup of old BTRFS root snapshots";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/sddm"
      "/var/lib/systemd/coredump"
      "/var/lib/systemd/timers"
      "/var/lib/tailscale"
      "/var/log"
      {
        directory = "/var/db/sudo/lectured";
        mode = "0700";
      }
    ];
    files = [ ];
  };
}
