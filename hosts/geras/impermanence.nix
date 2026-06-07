{ impermanence, ... }:

{
  imports = [ impermanence.nixosModules.impermanence ];

  # Use systemd-based initrd so we can run a service before the root is mounted.
  boot.initrd.systemd.enable = true;
  boot.initrd.supportedFilesystems = [ "btrfs" ];

  # On each boot, delete @root and restore it from the empty @root-blank snapshot.
  # This runs after LUKS is unlocked and before the root filesystem is mounted.
  boot.initrd.systemd.services.rollback = {
    description = "Rollback BTRFS root subvolume to blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@luks-adfc686d-fd51-471c-afb1-1313b9874d46.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ /dev/mapper/luks-adfc686d-fd51-471c-afb1-1313b9874d46 /mnt
      mkdir -p /mnt/old_roots
      timestamp=$(stat -c %Y /mnt/@root)
      btrfs subvolume snapshot -r /mnt/@root "/mnt/old_roots/$timestamp"
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
      "/etc/NetworkManager/system-connections"
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
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
