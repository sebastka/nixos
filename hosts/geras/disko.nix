{ disko, ... }:

{
  imports = [ disko.nixosModules.disko ];

  # Declarative partitioning, used by scripts/install.sh to wipe, format and mount the disk.
  # Layout: ESP + single LUKS container holding BTRFS subvolumes (swapfile included, so one passphrase).
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1"; # Check with lsblk on the live ISO before installing
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
            mountOptions = [
              "fmask=0077"
              "dmask=0077"
            ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot"; # Passphrase is prompted when formatting, kept as recovery
            settings = {
              allowDiscards = true;
              # Unlock with the Yubikey (FIDO2 + PIN + touch), enrolled by scripts/install.sh.
              # Falls back to the passphrase prompt if the Yubikey is not plugged in within 10s.
              crypttabExtraOpts = [
                "fido2-device=auto"
                "token-timeout=10"
              ];
            };
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@swap" = {
                  mountpoint = "/.swapvol";
                  swap.swapfile.size = "16G";
                };
              };
              # Empty snapshot of @root, restored on each boot by ./impermanence.nix once re-enabled.
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
