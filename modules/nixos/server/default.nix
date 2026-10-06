{ ... }:

{
  imports = [
    ./zabbix-agent.nix
  ];

  networking.useDHCP = false;
  networking.useNetworkd = true;
  services.resolved.enable = true;

  # Unattended upgrades to what is merged on master (dependency updates come from the nightly
  # "Update dependencies" workflow, at 02:00 UTC). Reboots only when the kernel/initrd changed.
  system.autoUpgrade = {
    enable = true;
    flake = "github:sebastka/nixos";
    dates = "04:30";
    randomizedDelaySec = "30min";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };
}
