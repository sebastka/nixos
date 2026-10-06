{ nixos-hardware, pkgs-unstable, ... }:

# Installing zeus (Dual boot with Windows). See also README.md, "Installing a host".
#
# Before installing, in this order:
# 1. In Windows: save the BitLocker recovery keys of both drives (manage-bde -protectors -get C:), then suspend
#    BitLocker as administrator: Suspend-BitLocker -MountPoint C: -RebootCount 0. Enrolling our Secure Boot keys
#    changes what the TPM measures, so Windows would otherwise ask for the recovery key.
# 2. Firmware: CSM disabled, Secure Boot mode Custom, delete only the PK (Setup Mode). Keep dbx.
# 3. Live ISO: scripts/install.sh zeus. Will install to the disk with serial S4EVNS0N905239P (./disko.nix)
#
# After installing:
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
  ];

  networking.hostName = "zeus";

  # Dual boot: Windows is on its own disks (nvme1n1, nvme2n1) with its own ESP, never touched here. This ESP
  # (./disko.nix) only has NixOS, the default boot entry. Windows: firmware boot menu (F12), or from NixOS
  # `sudo efibootmgr --bootnext <Windows Boot Manager's number>` then reboot.

  # systemd-based initrd: unit-based stage 1, enables FIDO2 LUKS unlock via systemd-cryptenroll.
  boot.initrd.systemd.enable = true;
  boot.initrd.verbose = false; # Less initrd chatter around the LUKS prompt
  boot.consoleLogLevel = 3;

  # US HHKB (Happy Hacking Keyboard): Control and the Fn layer are in the keyboard itself, nothing to remap.
  # Also the layout of the LUKS passphrase prompt (initrd).
  console.keyMap = "us";
  services.xserver.xkb.layout = "us";

  home-manager.extraSpecialArgs = { inherit pkgs-unstable; };

  system.stateVersion = "26.05";
}
