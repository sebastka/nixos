{
  lib,
  modulesPath,
  ...
}:

# Gigabyte X570 AORUS XTREME, AMD Ryzen 9 5950X, Radeon RX 6800 XT, 3 NVMe (NixOS: 970 EVO Plus, see ./disko.nix).
# As `nixos-generate-config --show-hardware-config --no-filesystems` on the live ISO. Its microcode line comes from
# nixos-hardware's common-cpu-amd (./default.nix).
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "sr_mod" # The Blu-ray drive (ASUS BW-16D1HT)
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Filesystems, LUKS and swap are generated from ./disko.nix.

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
