{ lib, ... }:

# MacBook Pro 14" 2021, M1 Pro (j314s), 16 GB. Internal NVMe: Apple's containers and macOS, the ESP and the NixOS
# partition. Kernel modules come from the Apple Silicon support module.
{
  # ESP made by the Asahi installer (Fedora's, kept: m1n1, U-Boot and vendorfw/ are on it). Not in ./disko.nix,
  # which would format it.
  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/609c77fe-7078-4725-862f-0a776aeae96e";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # LUKS, BTRFS and swap are generated from ./disko.nix.

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
