{ lib, ... }:

{
  # Run nixos-generate-config on boreas and replace this file with the result.
  # Placeholder until boreas is set up, so the configuration evaluates.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
