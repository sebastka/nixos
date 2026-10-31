{ config, ... }:

{
  imports = [
    ./smartd.nix
    ./zabbix-agent.nix
  ];

  networking.useDHCP = false;
  networking.useNetworkd = true;
  services.resolved.enable = true;

  # No nixpkgs in the system: its registry entry and NIX_PATH (`nix shell nixpkgs#...`, unused on servers) put the
  # whole source tree (~90,000 files) in every generation's closure, and file's small disk ran out of inodes.
  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };
  # Nor the NixOS manual (and `man configuration.nix`): its options.json is built from nixpkgs' tree, copied to the
  # host for each deploy built there (bin/build)
  documentation.nixos.enable = false;
  home-manager.sharedModules = [ { manual.manpages.enable = false; } ]; # man home-configuration.nix, the same way
  # Identical files in the store (most of it, from one update to the next) as one inode, hard-linked
  nix.settings.auto-optimise-store = true;

  # Unattended upgrades to what is merged on master (dependency updates come from the nightly
  # "Update dependencies" workflow, at 02:00 UTC). Reboots only when the kernel/initrd changed.
  system.autoUpgrade = {
    enable = true;
    flake = "github:sebastka/nixos#${config.networking.hostName}"; # Explicit, not from the running hostname
    upgrade = false; # --upgrade only updates root's channels, unused with flakes
    # Fail instead of resolving inputs missing from master's flake.lock (as bin/build)
    flags = [ "--no-update-lock-file" ];
    dates = "04:30"; # After helios (04:00, hosts/helios): it's the DNS
    randomizedDelaySec = "30min";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };
}
