{
  nixos-hardware,
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:

# Installing hermes (Raspberry Pi 4,). See also README.md, "Installing a host".
#
# 1. On geras, enable aarch64 emulation (boot.binfmt.emulatedSystems in hosts/geras/default.nix) and rebuild.
# 2. Build the SD card image of this configuration (mostly from the binary cache):
#      nix build .#nixosConfigurations.hermes.config.system.build.sdImage
# 3. Flash it to the SD card:
#      zstd -dc result/sd-image/*.img.zst | sudo dd of=/dev/<SD card> bs=4M conv=fsync status=progress
#    The root partition grows to the whole card on first boot.
# 4. Boot hermes, then restore its SSH host key, so it can decrypt its secrets (sops-nix), and redeploy:
#      sops decrypt --extract '["ssh_host_ed25519_key"]' secrets/hermes-ssh-host-key.sops.yaml \
#        | ssh hermes.home.karlsen.fr 'sudo install -m 600 /dev/stdin /etc/ssh/ssh_host_ed25519_key'
#      ssh hermes.home.karlsen.fr 'sudo reboot'
#    Until then, sebastian has no password (it's a secret) but logs in with SSH keys.
#
# After installing:
# - Remove Debian's hermes host key from users/sebastian/ssh/known_hosts.d/private and ~/.ssh/known_hosts
#   (the new one is in modules/nixos/common/openssh.nix).
{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    "${modulesPath}/installer/sd-card/sd-image.nix" # system.build.sdImage, and / and /boot/firmware by label
    ./hardware-configuration.nix
    ../../modules/nixos/common
    ../../modules/nixos/server
  ];

  networking.hostName = "hermes";

  systemd.network.networks."eth0" = {
    matchConfig.MACAddress = "dc:a6:32:e7:41:c9";
    networkConfig.DHCP = "ipv4";
  };

  systemd.network.networks."wlan0" = {
    matchConfig.MACAddress = "dc:a6:32:e7:41:ca";
    networkConfig.DHCP = "no";
    linkConfig.ActivationPolicy = "always-down";
  };

  # RPi4 boots via U-Boot and extlinux, not EFI/systemd-boot.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Serial console on the GPIO UART (as on Debian: enable_uart=1, console=ttyS1)
  boot.kernelParams = [
    "console=ttyS1,115200n8"
    "console=tty0"
  ];

  # SD card image: the Pi 4 part of nixpkgs' sd-image-aarch64.nix (without its installer profile: base.nix)
  sdImage = {
    compressImage = true;
    populateFirmwareCommands =
      let
        configTxt = pkgs.writeText "config.txt" ''
          [pi4]
          kernel=u-boot-rpi4.bin
          enable_gic=1
          armstub=armstub8-gic.bin
          disable_overscan=1
          arm_boost=1

          [all]
          arm_64bit=1
          # U-Boot needs it, and the serial console uses it
          enable_uart=1
          avoid_warnings=1
        '';
      in
      ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
        cp ${configTxt} firmware/config.txt
        cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin firmware/u-boot-rpi4.bin
        cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin firmware/armstub8-gic.bin
        cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/bcm2711-rpi-4-b.dtb firmware/
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  system.stateVersion = "26.05";
}
