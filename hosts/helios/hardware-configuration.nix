{ lib, modulesPath, ... }:

# Protectli FW6 (BIOS 5.12): Intel Core i5-8250U, 16 GB, 120 GB mSATA (./disko.nix), 6 Intel I211 ports (igb,
# ./network.nix). As `nixos-generate-config --show-hardware-config --no-filesystems` on NixOS, plus usbhid and
# usb_storage: it lists only what was plugged in, and they keep a USB keyboard (GRUB, early boot) and a rescue stick
# working.
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.cpu.intel.updateMicrocode = true;

  # Filesystems and swap are generated from ./disko.nix.

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
