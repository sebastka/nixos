{ nixos-hardware, lib, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ../../modules/nixos/common
    ../../modules/nixos/server
  ];

  networking.hostName = "hermes";

  systemd.network.networks."eth0" = {
    matchConfig.MACAddress = "dc:a6:32:e7:41:c9";
    networkConfig.DHCP = "ipv4";
  };

  systemd.network.networks."wlan0" = {
    matchConfig.MACAddress = "dc:a6:32:e7:41:ca";
    networkConfig.DHCP = "no";
    linkConfig.ActivationPolicy = "always-down";
  };

  # RPi4 boots via extlinux, not EFI/systemd-boot.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.generic-extlinux-compatible.enable = true;

  system.stateVersion = "26.05";
}
