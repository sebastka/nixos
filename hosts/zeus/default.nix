{ nixos-hardware, pkgs-unstable, ... }:

# Installing zeus (Dual boot with Windows). See also README.md, "Installing a host".
#
# Before installing, in this order:
# 1. In Windows: save the BitLocker recovery keys of both drives (manage-bde -protectors -get C:), then suspend
#    BitLocker as administrator: Suspend-BitLocker -MountPoint C: -RebootCount 0. Enrolling our Secure Boot keys
#    changes what the TPM measures, so Windows would otherwise ask for the recovery key.
# 2. Firmware: CSM disabled, Secure Boot mode Custom, delete only the PK (Setup Mode). Keep dbx. For wake-on-LAN:
#    Wake on LAN enabled, ErP disabled (it cuts the network card's power when off).
# 3. Live ISO: scripts/install.sh zeus. Will install to the disk with serial S4EVNS0N905239P (./disko.nix)
#
# After installing:
# - First boot: lanzaboote enrolls our Secure Boot keys (Microsoft's included) and reboots. Check: `bootctl status`
#   shows Secure Boot enabled (user).
# - Then the TPM, for LUKS (./disko.nix), bound to PCR 7 (Secure Boot's state and keys): the disk unlocks by itself
#   only while Secure Boot is on with our keys, the passphrase otherwise. And a recovery key, kept in Bitwarden (the
#   firmware TPM is cleared by some firmware updates: passphrase, then enroll again with --wipe-slot=tpm2):
#     sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/disk/by-partlabel/disk-main-luks
#     sudo systemd-cryptenroll --recovery-key /dev/disk/by-partlabel/disk-main-luks
# - Boot Windows once (firmware boot menu, F12), then resume BitLocker: Resume-BitLocker -MountPoint C:
# - Remove old boot entries (sudo efibootmgr -b <number> -B) and \EFI\<old entries> on Windows' ESP.
# - Remove old zeus host key from users/sebastian/ssh/known_hosts.d/private and ~/.ssh/known_hosts
{
  imports = [
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-cpu-amd-pstate
    nixos-hardware.nixosModules.common-gpu-amd
    nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/nixos/secure-boot.nix
    ../../modules/nixos/common
    ../../modules/nixos/desktop
    ../../modules/nixos/gnome
  ];

  networking.hostName = "zeus";

  # Dual boot: Windows is on its own disks (Samsung 980 PRO 500 GB and 2 TB; their nvme names change between boots)
  # with its own ESP, never touched here. This ESP (./disko.nix) only has NixOS, the default boot entry. Windows:
  # firmware boot menu (F12), or from NixOS `sudo efibootmgr --bootnext <Windows Boot Manager's number>` then reboot.

  # Wake-on-LAN by magic packet, on both cards: the Aquantia AQC107 10 GbE (enp6s0, atlantic; the MAC in
  # hosts/helios/lan.nix, so `wake zeus` from helios) and the Intel I211 1 GbE (enp7s0, if the cable is there:
  # wakeonlan -i 192.168.255.255 18:c0:4d:85:cd:2f). It boots the default entry, NixOS, which the TPM unlocks without
  # input (./disko.nix).
  networking.interfaces.enp6s0.wakeOnLan.enable = true;
  networking.interfaces.enp7s0.wakeOnLan.enable = true;
  # Nor back to sleep on its own while used over ssh (builds): no suspend when idle, neither at GDM's login screen nor
  # in a GNOME session (a default for every user, changeable in Settings > Power).
  services.displayManager.gdm.autoSuspend = false;
  programs.dconf.profiles.user.databases = [
    { settings."org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing"; }
  ];

  # systemd-based initrd: unit-based stage 1, enables TPM2 LUKS unlock via systemd-cryptenroll.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;
  boot.initrd.verbose = false; # Less initrd chatter around the LUKS prompt
  boot.consoleLogLevel = 3;

  # US HHKB (Happy Hacking Keyboard): Control and the Fn layer are in the keyboard itself, nothing to remap.
  # Also the layout of the LUKS passphrase prompt (initrd).
  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  home-manager.extraSpecialArgs = { inherit pkgs-unstable; };

  system.stateVersion = "26.05";
}
