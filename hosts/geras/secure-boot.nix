{ lanzaboote, lib, pkgs, ... }:

{
  imports = [ lanzaboote.nixosModules.lanzaboote ];

  # Lanzaboote replaces systemd-boot and signs the kernel/initrd with our own Secure Boot keys.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    # Pre-generated keys (secrets/geras-secure-boot.sops.yaml), restored by scripts/install.sh.
    pkiBundle = "/var/lib/sbctl";

    # On first boot, stage the keys on the ESP and reboot: systemd-boot then enrolls them,
    # provided the firmware is in Setup Mode. Microsoft keys are included by default,
    # which the NVIDIA dGPU option ROM needs.
    autoEnrollKeys = {
      enable = true;
      autoReboot = true;
    };
  };

  environment.systemPackages = [ pkgs.sbctl ];
}
