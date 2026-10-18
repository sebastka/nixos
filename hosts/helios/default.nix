{ lib, ... }:

# Installing helios (the router: replaces Debian, set up by Ansible until now). See also README.md, "Installing a host".
# The LAN keeps its DHCP, DNS and internet while helios is being installed (4.), except during the reboot (5.):
# leases last 24 h, so its clients keep their addresses.
#
# Before installing:
# 1. Secrets: from Ansible's secrets (secret_cloudflare_api_token, secret_dnssec_*_private), fill in
#    secrets/.helios.sops.yaml, then encrypt it: sops -e secrets/.helios.sops.yaml > secrets/helios.sops.yaml
#    Then add helios to the shared secrets (Yubikey PIN): sops updatekeys -y secrets/common.sops.yaml
# 2. Commit and push: scripts/install.sh pulls origin/master on the live ISO.
# 3. Firmware (AMI): legacy BIOS boot, as the FW6's BIOS updates need: Secure Boot off (it can't be on with legacy
#    boot), CSM on, boot mode Legacy (not UEFI). No TPM: the FW6's firmware has no PTT, hence a disk without
#    encryption (./disko.nix).
# 4. Boot helios's installer (./installer.nix: the live ISO as the router, so the LAN keeps its DHCP, DNS and internet
#    while helios's disk is installed). Build it on zeus, then dd it to a USB stick:
#      nix build .#nixosConfigurations.helios-installer.config.system.build.isoImage
#    In the firmware's boot menu, its legacy (non-UEFI) entry: the ISO boots both ways, and install.sh installs GRUB
#    for the mode it was booted in. Check on it: [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
#    Screen and keyboard on helios, WAN cable in enp1s0 (port 1) as usual: it gets the public IP from the ISP by DHCP.
#    Then from geras (Yubikey there, no password: the installer has its SSH key):
#      scripts/install.sh helios nixos@192.168.0.1
# 5. Reboot, without the USB stick: GRUB boots NixOS by itself (no passphrase, no Secure Boot keys to enroll).
#
# After installing:
# - Check: DHCP (journalctl -u kea-dhcp4-server), DNS (dig @192.168.0.1 hermes.home.karlsen.fr +dnssec, and a public
#   name), the certificate (journalctl -u acme-order-renew-karlsen.fr), the public IP in Cloudflare
#   (journalctl -u cloudflare-dyndns), ad blocking (journalctl -u unbound | grep oisd).
# - Remove Debian's helios host key from users/sebastian/ssh/known_hosts.d/private and ~/.ssh/known_hosts
#   (the new one is in modules/nixos/common/openssh.nix).
#
# Updates: nightly from master, rebooting between 04:00 and 06:00 when needed (modules/nixos/server). The previous
# generations stay in the boot menu.
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./network.nix
    ./firewall.nix
    ./dhcp.nix
    ./dns.nix
    ./acme.nix
    ./wake.nix
    ../../modules/nixos/common
    ../../modules/nixos/server
  ];

  networking.hostName = "helios";

  # Legacy BIOS boot, with GRUB (on the disk's BIOS boot partition, ./disko.nix): the FW6's BIOS updates need the
  # firmware in legacy mode. No UEFI then, so neither systemd-boot (modules/nixos/common) nor Secure Boot, which without
  # disk encryption would protect little anyway: its keys would sit on the same unencrypted disk.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    configurationLimit = 5; # As systemd-boot's (modules/nixos/common)
  };

  # systemd-based initrd: unit-based stage 1, as on the other hosts. Without its TPM support: helios has no TPM, nor
  # LUKS (./disko.nix).
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = false;
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 3;

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "2G";
  };

  system.stateVersion = "26.05";
}
