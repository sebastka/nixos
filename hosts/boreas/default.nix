{
  nixos-apple-silicon,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

# Installing boreas (MacBook Pro 14" M1 Pro, j314s; replaces Fedora Asahi Remix, macOS stays).
# See also README.md, "Installing a host". The disk holds Apple's partitions: never use an automatic partitioner.
#
# Before installing:
# 1. Firmware hash: `sudo sha256sum /boot/efi/vendorfw/firmware.cpio` on Fedora must match peripheralFirmwareDirectory
#    below (the file is not redistributable and this repository is public: only its hash is here). It only changes
#    when the Asahi installer runs again.
# 2. Make a NixOS Apple Silicon installer USB stick (https://github.com/nix-community/nixos-apple-silicon/releases),
#    boot it from Fedora's entry in the boot picker (hold the power button), then in the installer:
#      sgdisk -p /dev/nvme0n1          # Check: p4 "EFI - FEDOR" (ESP, kept), p5 /boot and p6 btrfs (Fedora's)
#      sgdisk -d 6 /dev/nvme0n1        # Delete Fedora's root...
#      sgdisk -d 5 /dev/nvme0n1        # ...and /boot
#      sgdisk -n 0:0:0 /dev/nvme0n1    # New partition in the largest free block (the freed space)
#      sgdisk -p /dev/nvme0n1          # Its number N (usually 5), then name it:
#      sgdisk -c N:nixos /dev/nvme0n1
#    Never touch p1 (iBootSystemContainer), the macOS container or the last one (RecoveryOSContainer).
# 3. scripts/install.sh boreas: LUKS and BTRFS on the "nixos" partition only (./disko.nix), mounts the ESP
#    (./hardware-configuration.nix), adds firmware.cpio to the Nix store, then installs.
#
# After installing:
# - Remove Fedora's files from the ESP (EFI/fedora): NixOS uses EFI/systemd and m1n1/ (it updates m1n1 and U-Boot).
# - The boot picker still names the OS "Fedora" (its macOS stub volume): rename it from macOS if needed.
# - Remove Fedora's boreas host key from users/sebastian/ssh/known_hosts.d/private and ~/.ssh/known_hosts
#   (the new one is in modules/nixos/common/openssh.nix).
{
  imports = [
    nixos-apple-silicon.nixosModules.apple-silicon-support
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos/common
    ../../modules/nixos/desktop
  ];

  networking.hostName = "boreas";

  # systemd-boot on the ESP made by the Asahi installer (loaded by m1n1 and U-Boot). EFI variables can't be set.
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  # The ESP is only 500 MB, and holds the kernels and initrds too
  boot.loader.systemd-boot.configurationLimit = lib.mkForce 3;

  # systemd-based initrd: unit-based stage 1, enables FIDO2 LUKS unlock via systemd-cryptenroll.
  # The internal keyboard works in it (spi-hid-apple, from the Apple Silicon support module).
  boot.initrd.systemd.enable = true;
  boot.initrd.verbose = false; # Less initrd chatter around the LUKS prompt
  boot.consoleLogLevel = 3;

  hardware.asahi.enable = true;

  # nixos-apple-silicon tracks nixos-unstable: its video decoder firmware is not in nixos-26.05 yet
  nixpkgs.overlays = [ (final: prev: { inherit (pkgs-unstable) avd-fw; }) ];

  # Peripheral firmware (Wi-Fi, Bluetooth, webcam...), extracted from macOS by the Asahi installer into
  # vendorfw/firmware.cpio on the ESP. A flake can't read /boot, and the file can't be in this public repository:
  # it's added to the Nix store by its hash (scripts/install.sh, or `sudo nix-store --add-fixed sha256
  # /boot/vendorfw/firmware.cpio` after a new Asahi installer run, with the new hash here).
  hardware.asahi.peripheralFirmwareDirectory = pkgs.linkFarm "asahi-peripheral-firmware" {
    "firmware.cpio" = pkgs.requireFile {
      name = "firmware.cpio";
      sha256 = "43f588e63f5f96d746379a2c0f393aea25645a04bd4a90f876aa472ce49e79b7"; # sha256sum of the file
      message = "Add boreas's Asahi firmware: sudo nix-store --add-fixed sha256 /boot/vendorfw/firmware.cpio";
    };
  };

  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [ "--operator=sebastian" ];

  console.keyMap = "no";
  services.xserver.xkb = {
    layout = "no";
    model = "applealu_iso";
    variant = "";
  };

  home-manager.extraSpecialArgs = { inherit pkgs-unstable; };

  system.stateVersion = "26.05";
}
