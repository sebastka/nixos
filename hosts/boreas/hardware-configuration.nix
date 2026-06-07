{ lib, ... }:

{
  # Run nixos-generate-config on boreas and replace this file with the result.
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
