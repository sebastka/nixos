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

  hardware.asahi.enable = true;

  # nixos-apple-silicon tracks nixos-unstable: its video decoder firmware is not in nixos-26.05 yet
  nixpkgs.overlays = [ (final: prev: { inherit (pkgs-unstable) avd-fw; }) ];

  # Firmware blobs extracted from macOS are required for Wi-Fi, Bluetooth, GPU, etc.
  # Copy them from macOS before installing: https://github.com/tpwrules/nixos-apple-silicon
  # Only enabled once ./firmware exists, so the configuration evaluates before boreas is set up.
  hardware.asahi.extractPeripheralFirmware = builtins.pathExists ./firmware;
  hardware.asahi.peripheralFirmwareDirectory = lib.mkIf (builtins.pathExists ./firmware) ./firmware;

  console.keyMap = "no";
  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };

  home-manager.extraSpecialArgs = { inherit pkgs-unstable; };

  system.stateVersion = "26.05";
}
