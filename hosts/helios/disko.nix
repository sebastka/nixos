{ disko, ... }:

{
  imports = [ disko.nixosModules.disko ];

  # Declarative partitioning, used by scripts/install.sh to wipe, format and mount the disk.
  # Layout: ESP + single LUKS container holding BTRFS subvolumes (swapfile included), as on the other hosts.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/ata-Protectli_120GB_mSATA_D382072503A100010941"; # The only disk
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
            name = "cryptroot"; # Passphrase is prompted when formatting, kept as recovery (helios's console)
            settings = {
              allowDiscards = true;
              # Unattended unlock with the TPM (Intel PTT), bound to the Secure Boot state (PCR 7): helios comes back
              # by itself after a power cut or an upgrade. Enrolled once Secure Boot is set up (./default.nix).
              # Without it (or if the Secure Boot state changes), the passphrase is asked on the console.
              crypttabExtraOpts = [ "tpm2-device=auto" ];
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
                  swap.swapfile.size = "8G";
                };
              };
            };
          };
        };
      };
    };
  };
}
