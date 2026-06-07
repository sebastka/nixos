{ nixos-hardware, pkgs-unstable, ... }:

{
  imports = [
    nixos-hardware.nixosModules.dell-xps-15-7590
    ./hardware-configuration.nix
    ../../modules/nixos/common
    ../../modules/nixos/desktop
  ];

  networking.hostName = "geras";

  # Power off the NVIDIA GTX 1650 dGPU at boot to save battery (uses bbswitch).
  hardware.nvidiaOptimus.disable = true;

  # The XPS 15 is notorious for a BD PROCHOT issue: the CPU throttles itself
  # based on a false thermal signal from the battery sensor, not actual CPU temp.
  services.throttled.enable = true;

  # Uncomment to build aarch64 (e.g. hermes) on geras via QEMU emulation.
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [ "--operator=sebastian" ];

  console.keyMap = "no";
  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };

  home-manager.extraSpecialArgs = { inherit pkgs-unstable; };

  system.stateVersion = "26.05";
}
