{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/mapper/luks-9a13ab37-7df1-4b5f-8965-74feb43c1cd3";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "noatime"
    ];
  };

  boot.initrd.luks.devices."luks-9a13ab37-7df1-4b5f-8965-74feb43c1cd3".device =
    "/dev/disk/by-uuid/9a13ab37-7df1-4b5f-8965-74feb43c1cd3";

  # fileSystems."/persist" = {
  #   device = "/dev/mapper/luks-9a13ab37-7df1-4b5f-8965-74feb43c1cd3";
  #   fsType = "btrfs";
  #   options = [
  #     "subvol=@persist"
  #     "compress=zstd"
  #     "noatime"
  #   ];
  #   neededForBoot = true;
  # };

  fileSystems."/home" = {
    device = "/dev/mapper/luks-9a13ab37-7df1-4b5f-8965-74feb43c1cd3";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/luks-9a13ab37-7df1-4b5f-8965-74feb43c1cd3";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/866B-DEEE";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
