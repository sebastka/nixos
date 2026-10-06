{ lib, ... }:

# Raspberry Pi 4 Model B Rev 1.4, 8 GB, booting from the SD card (116 GB).
# Filesystems: the SD card image's, by label (NIXOS_SD and FIRMWARE), defined by sd-image.nix (./default.nix).
{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "usb_storage"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
