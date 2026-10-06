{ disko, ... }:

{
  imports = [ disko.nixosModules.disko ];

  # Declarative partitioning, used by scripts/install.sh to wipe, format and mount the disk.
  # Layout: ESP + single LUKS container holding BTRFS subvolumes (swapfile included, so one passphrase).
  # Only this disk: the Windows disks (980 PRO 500 GB and 2 TB) and their ESP are left alone (dual boot).
  disko.devices.disk.main = {
    type = "disk";
    # Samsung 970 EVO Plus 500 GB, by serial number: the nvme0n1/1n1/2n1 names can change between boots
    device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EVNS0N905239P";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot"; # Passphrase is prompted when formatting
            settings = {
              allowDiscards = true;
              # Passphrase by default: no fido2-device=, so no waiting for a Yubikey. The Yubikey enrolled by
              # scripts/install.sh (FIDO2) is still tried once first: used if plugged in at boot (PIN and touch).
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "16G";
                };
              };
              # Empty snapshot of @root, for impermanence later (as on geras)
              postCreateHook = ''
                MNTPOINT=$(mktemp -d)
                mount -t btrfs -o subvol=/ /dev/mapper/cryptroot "$MNTPOINT"
                trap 'umount "$MNTPOINT"; rm -rf "$MNTPOINT"' EXIT
                btrfs subvolume snapshot -r "$MNTPOINT/@root" "$MNTPOINT/@root-blank"
              '';
            };
          };
        };
      };
    };
  };
}
