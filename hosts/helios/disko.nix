{ disko, ... }:

{
  imports = [ disko.nixosModules.disko ];

  # Declarative partitioning, used by bin/install-host to wipe, format and mount the disk.
  # Layout: ESP + BTRFS subvolumes (swapfile included), as on the other hosts but not encrypted: helios has no TPM
  # (the FW6's firmware has no PTT), and a router must come back by itself after a power cut or an upgrade's reboot,
  # with nobody to type a passphrase. Its secrets on disk (sops-nix's: DNSSEC keys, Cloudflare token, SSH host key)
  # are readable by whoever has the box.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/ata-Protectli_120GB_mSATA_D382072503A100010941"; # The only disk
    content = {
      type = "gpt";
      partitions = {
        # Legacy BIOS boot (./default.nix: the FW6's BIOS updates need it): GRUB's core image, on a GPT disk
        bios = {
          size = "1M";
          type = "EF02";
        };
        # /boot. An ESP all the same, should helios boot UEFI again (no repartitioning)
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
        root = {
          size = "100%";
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
}
