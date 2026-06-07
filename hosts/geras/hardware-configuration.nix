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

  # Main LUKS container: holds the BTRFS volume with subvolumes for root, /home, /nix, and /persist.
  boot.initrd.luks.devices."luks-adfc686d-fd51-471c-afb1-1313b9874d46".device =
    "/dev/disk/by-uuid/adfc686d-fd51-471c-afb1-1313b9874d46";

  fileSystems."/" = {
    device = "/dev/mapper/luks-adfc686d-fd51-471c-afb1-1313b9874d46";
    fsType = "btrfs";
    options = [
      "subvol=@root"
      "compress=zstd"
      "noatime"
    ];
  };

  # Mounted early so impermanence can bind-mount persistent files before activation.
  fileSystems."/persist" = {
    device = "/dev/mapper/luks-adfc686d-fd51-471c-afb1-1313b9874d46";
    fsType = "btrfs";
    options = [
      "subvol=@persist"
      "compress=zstd"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/mapper/luks-adfc686d-fd51-471c-afb1-1313b9874d46";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/luks-adfc686d-fd51-471c-afb1-1313b9874d46";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/34C0-24D2";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Swap LUKS container: separate encrypted partition for swap.
  boot.initrd.luks.devices."luks-bc43092a-9fe4-4ec7-af2c-6d1221b09d97".device =
    "/dev/disk/by-uuid/bc43092a-9fe4-4ec7-af2c-6d1221b09d97";
  swapDevices = [
    { device = "/dev/mapper/luks-bc43092a-9fe4-4ec7-af2c-6d1221b09d97"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
