{ nixos-hardware, pkgs-unstable, ... }:

{
  imports = [
    nixos-hardware.nixosModules.dell-xps-15-7590
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos/secure-boot.nix
    # ./impermanence.nix
    ../../modules/nixos/common
    ../../modules/nixos/desktop
  ];

  networking.hostName = "geras";

  # systemd-based initrd: unit-based stage 1, enables TPM2/FIDO2 LUKS unlock via systemd-cryptenroll.
  boot.initrd.systemd.enable = true;
  boot.initrd.verbose = false; # Less initrd chatter around the LUKS prompt
  boot.consoleLogLevel = 3; # Hide kernel errors like i915's lspcon probe; critical messages still show

  # NVIDIA GTX 1650 dGPU: unused, powered off by the kernel's runtime PM (see the udev rule below),
  # instead of bbswitch (hardware.nvidiaOptimus.disable, unmaintained out-of-tree module).
  # No driver may bind to it, or it would stay awake.
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidiafb"
    "nvidia-drm"
    "nvidia-uvm"
    "nvidia-modeset"
  ];

  # The XPS 15 is notorious for a BD PROCHOT issue: the CPU throttles itself
  # based on a false thermal signal from the battery sensor, not actual CPU temp.
  services.throttled.enable = true;

  # Power-saving tunables from `powertop`, set explicitly instead of `powertop --auto-tune`.
  # Never combine with bbswitch: runtime PM on the dGPU racing with bbswitch at boot froze geras.
  services.udev.extraRules = ''
    # Runtime PM for all PCI devices, including the NVIDIA dGPU (should reach D3cold)
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    # SATA link power management
    ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="med_power_with_dipm"
  '';
  boot.extraModprobeConfig = "options snd_hda_intel power_save=1"; # Audio codec power management
  boot.kernel.sysctl = {
    "kernel.nmi_watchdog" = 0;
    "vm.dirty_writeback_centisecs" = 1500; # VM writeback timeout: 15s
  };

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
