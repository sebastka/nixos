{
  lib,
  nixos-hardware,
  pkgs,
  pkgs-unstable,
  ...
}:

# Installing zeus (Dual boot with Windows). See also README.md, "Installing a host".
#
# Before installing, in this order:
# 1. In Windows: save the BitLocker recovery keys of both drives (manage-bde -protectors -get C:), then suspend
#    BitLocker as administrator: Suspend-BitLocker -MountPoint C: -RebootCount 0. Enrolling our Secure Boot keys
#    changes what the TPM measures, so Windows would otherwise ask for the recovery key.
# 2. Firmware: CSM disabled, Secure Boot mode Custom, delete only the PK (Setup Mode). Keep dbx. For wake-on-LAN:
#    Wake on LAN enabled, ErP disabled (it cuts the network card's power when off).
# 3. Live ISO: bin/install-host zeus. Will install to the disk with serial S4EVNS0N905239P (./disko.nix)
#    The Yubikey (USB-C) doesn't fit zeus: on the live ISO passwd and ip a, then from geras
#    bin/install-host zeus nixos@<IP> (README.md, "Installing a host").
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
    ../../modules/nixos/cinnamon
    ../../users/sebastian/hosts/zeus.nix
  ];

  networking.hostName = "zeus";

  # Dual boot: Windows is on its own disks (Samsung 980 PRO 500 GB and 2 TB; their nvme names change between boots)
  # with its own ESP, never touched here. This ESP (./disko.nix) only has NixOS, the default boot entry. Windows:
  # firmware boot menu (F12), or from NixOS `boot-windows` then reboot: the next boot only, NixOS's afterwards.
  environment.systemPackages = [
    pkgs.efibootmgr
    (pkgs.writeShellApplication {
      name = "boot-windows";
      runtimeInputs = [ pkgs.efibootmgr ];
      text = ''
        # Windows Boot Manager's entry, by its name: entry numbers change (firmware updates, new entries)
        entry="$(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)\* Windows Boot Manager.*/\1/p')"
        [ -n "$entry" ] || { echo "No Windows Boot Manager entry (efibootmgr)" >&2; exit 1; }
        sudo efibootmgr --bootnext "$entry" > /dev/null
        echo "Next boot only: Windows (Boot$entry). Reboot to start it."
      '';
    })
  ];

  # Wake-on-LAN by magic packet, on both cards: the Aquantia AQC107 10 GbE (enp6s0, atlantic; the MAC in
  # hosts/helios/lan.nix, so `wake zeus` from helios) and the Intel I211 1 GbE (enp7s0, if the cable is there:
  # wakeonlan -i 192.168.255.255 18:c0:4d:85:cd:2f). It boots the default entry, NixOS, which the TPM unlocks without
  # input (./disko.nix).
  networking.interfaces.enp6s0.wakeOnLan.enable = true;
  networking.interfaces.enp7s0.wakeOnLan.enable = true;
  # Nor back to sleep on its own while used over ssh (builds): no suspend when idle in a Cinnamon session, already
  # Cinnamon's default, kept whatever its next default (a default for every user, changeable in System Settings >
  # Power Management). LightDM's greeter doesn't suspend.
  programs.dconf.profiles.user.databases = [
    {
      settings."org/cinnamon/settings-daemon/plugins/power".sleep-inactive-ac-timeout =
        lib.gvariant.mkInt32 0;
    }
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
