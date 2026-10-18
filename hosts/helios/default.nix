{ ... }:

# Installing helios (the router: replaces Debian, set up by Ansible until now). See also README.md, "Installing a host".
# The LAN keeps its DHCP, DNS and internet while helios is being installed (4.), except during the reboots (5., 6.):
# leases last 24 h, so its clients keep their addresses.
#
# Before installing:
# 1. Secrets: from Ansible's secrets (secret_cloudflare_api_token, secret_dnssec_*_private), fill in
#    secrets/.helios.sops.yaml, then encrypt it: sops -e secrets/.helios.sops.yaml > secrets/helios.sops.yaml
#    Then add helios to the shared secrets (Yubikey PIN): sops updatekeys -y secrets/common.sops.yaml
# 2. Commit and push: scripts/install.sh pulls origin/master on the live ISO.
# 3. Firmware (AMI): enable the TPM (Intel PTT; Advanced > Trusted Computing, or PCH-FW Configuration). Secure Boot
#    mode Custom, delete only the PK (Setup Mode), keep dbx.
# 4. Boot helios's installer (./installer.nix: the live ISO as the router, so the LAN keeps its DHCP, DNS and internet
#    while helios's disk is installed). Build it on zeus, then dd it to a USB stick:
#      nix build .#nixosConfigurations.helios-installer.config.system.build.isoImage
#    Screen and keyboard on helios, WAN cable in enp1s0 (port 1) as usual: it gets the public IP from the ISP by DHCP.
#    Then from geras (Yubikey there, no password: the installer has its SSH key):
#      scripts/install.sh helios nixos@192.168.0.1
# 5. First boots: the LUKS passphrase on the console. Lanzaboote enrolls the Secure Boot keys and reboots.
# 6. Unattended unlock: enroll the TPM, bound to the Secure Boot state, then reboot to check:
#      sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks
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
    ../../modules/nixos/secure-boot.nix
    ../../modules/nixos/common
    ../../modules/nixos/server
  ];

  networking.hostName = "helios";

  # systemd-based initrd: unit-based stage 1, enables TPM2 (and FIDO2) LUKS unlock via systemd-cryptenroll.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 3;

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "2G";
  };

  system.stateVersion = "26.05";
}
