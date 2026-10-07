{ disko, ... }:

{
  imports = [ disko.nixosModules.disko ];

  # Only the "nixos" partition, made by hand in the space Fedora left (see ./default.nix): the rest of the disk is
  # Apple's (boot and recovery containers, macOS) and the ESP made by the Asahi installer (./hardware-configuration.nix).
  # disko only formats this partition: its wipe step only applies to whole disks.
  # Layout: single LUKS container holding BTRFS subvolumes (swapfile included, so one passphrase), as on geras.
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-partlabel/nixos";
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
}
