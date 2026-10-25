{ lib, ... }:

# The NFS server: NFSv4 only (one TCP port, 2049), the same paths and exports as file01, so clients
# keep their mounts and only the server address changes.
#
# The data is the btrfs labelled samsung_storage: file01's Samsung 9100 PRO, passed through as is
# from hera.
let
  lan = import ../helios/lan.nix;
  data = "/mnt/data_disk1";
  # Bind-mounted under /mnt/nfs, as on file01
  shares = [
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Videos"
    "homelab/k8s"
  ];
  bind = share: {
    name = "/mnt/nfs/${share}";
    value = {
      device = "${data}/${share}";
      fsType = "none";
      options = [
        "bind"
        "nofail"
        "x-systemd.requires-mounts-for=${data}"
      ];
    };
  };
in
{
  fileSystems = {
    ${data} = {
      device = "/dev/disk/by-label/samsung_storage";
      fsType = "btrfs";
      options = [
        "discard=async"
        "nofail" # The VM boots (and stays reachable over SSH) without it
      ];
    };
  }
  // lib.listToAttrs (map bind shares);

  services.nfs.server = {
    enable = true;
    # LAN: 192.168.0.0/24 (desktops), 192.168.0.0/16 (also the Talos nodes, for kubelet mounts).
    # Pods' range for homelab/k8s: a kubelet on the VM's own node (hera) mounts from that node's Cilium router address
    # (cilium_host, 10.244.x.x), not its LAN address. Cilium only lets the nodes in (host, remote-node), not pods.
    exports = ''
      /mnt/nfs/Documents                192.168.0.0/24(rw,sync,no_subtree_check)
      /mnt/nfs/Downloads                192.168.0.0/24(rw,sync,no_subtree_check)
      /mnt/nfs/Music                    192.168.0.0/24(rw,sync,no_subtree_check)
      /mnt/nfs/Pictures                 192.168.0.0/24(rw,sync,no_subtree_check)
      /mnt/nfs/Videos                   192.168.0.0/24(rw,sync,no_subtree_check)
      /mnt/nfs/homelab/k8s              192.168.0.0/16(rw,sync,no_subtree_check,no_root_squash) ${lan.clusterPods}(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  # NFSv4.1 and 4.2 only, over TCP
  services.nfs.settings.nfsd = {
    vers3 = false;
    "vers4.0" = false;
    "vers4.1" = true;
    "vers4.2" = true;
    udp = false;
  };

  # Port 2049: ./firewall.nix
}
