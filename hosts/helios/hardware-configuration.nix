{ lib, modulesPath, ... }:

# Protectli FW6 (BIOS 5.12): Intel Core i5-8250U, 16 GB, 120 GB mSATA (./disko.nix), 6 Intel I211 ports (igb,
# ./network.nix). From the hardware as seen by Debian: check against `nixos-generate-config --show-hardware-config`
# on the live ISO.
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

  # Filesystems, LUKS and swap are generated from ./disko.nix.

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
