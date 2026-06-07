{ nixos-apple-silicon, lib, pkgs-unstable, ... }:

{
  imports = [
    nixos-apple-silicon.nixosModules.apple-silicon-support
    ./hardware-configuration.nix
    ../../modules/nixos/common
    ../../modules/nixos/desktop
  ];

  networking.hostName = "boreas";

  # Asahi manages the bootloader: do not touch EFI variables.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # Firmware blobs extracted from macOS are required for Wi-Fi, Bluetooth, GPU, etc.
  # Copy them from macOS before installing: https://github.com/tpwrules/nixos-apple-silicon
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;

  console.keyMap = "no";
  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };

  home-manager.extraSpecialArgs = { inherit pkgs-unstable; };

  system.stateVersion = "26.05";
}
