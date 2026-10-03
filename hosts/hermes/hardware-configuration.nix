{ lib, ... }:

{
  # Run nixos-generate-config on the Pi and replace this file with the result.
  # Placeholder until the Pi is set up: label used by the NixOS SD card image.
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
