{
  pkgs, 
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/base
    ../../modules/desktop
    ../../modules/nb_NO.nix
    ../../modules/tailscale.nix
    ./nfs.nix
  ];

  # Nvidia
  hardware.nvidia.nvidiaSettings = true;
  hardware.nvidia.powerManagement.finegrained = false;
  hardware.nvidia.prime.offload.enable = false; 
  hardware.nvidia.prime.sync.enable = true;
  hardware.nvidia.prime.intelBusId = "PCI:0:2:0";
  hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0";

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "fjordmail-xps15";
  networking.domain = "home.karlsen.fr";

  # https://man.archlinux.org/man/NetworkManager-dispatcher.8.en
  # networking.networkmanager.dispatcherScripts = [
  #   {
  #     source = pkgs.writeText "checkNS" ''
  #       #!/usr/bin/env ${pkgs.bash}/bin/bash
  #       # Only allow local DNS from home network. Oterwise use defaults.
  #       set -eu
  #       iface="$1"
  #       action="$2"

  #       echo "$iface" | grep -q -x 'wlp59s0' || exit 0
  #       echo "$action" | grep -q -x 'up' || exit 0
  #       echo "$CONNECTION_ID" | grep -q 'NETGEAR30' && exit 0

  #       ${pkgs.networkmanager}/bin/nmcli device modify "$iface" ipv4.ignore-auto-dns yes
  #       ${pkgs.networkmanager}/bin/nmcli device modify "$iface" ipv6.ignore-auto-dns yes
  #       sed -i '/^domain home\.karlsen\.fr$/d' /etc/resolv.conf
  #     '';
  #     type = "basic";
  #   }
  # ];

  networking.extraHosts = 
    ''
      192.168.2.1 helios.home.karlsen.fr
      192.168.4.2 atlas.home.karlsen.fr
      192.168.4.60 paperless.homeswarm.atlas.home.karlsen.fr
    '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
