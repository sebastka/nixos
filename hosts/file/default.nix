{
  lib,
  modulesPath,
  ...
}:

# Installing file (KubeVirt VM in the homelab cluster: k8s/infrastructure/storage/file there).
# The NFS server that replaces file01 (Proxmox VM on hera), under a name of its own: file.home.karlsen.fr.
#
# 1. Build the KubeVirt disk image (on zeus):
#      nix build .#nixosConfigurations.file.config.system.build.image
# 2. Upload it into the VM's root DataVolume (it waits for an upload, see the homelab's manifests); the VM starts
#    by itself once it is in:
#      kubectl port-forward -n cdi svc/cdi-uploadproxy 18443:443 &
#      virtctl image-upload dv file-root -n file --no-create --image-path=result/*.qcow2 \
#        --uploadproxy-url=https://127.0.0.1:18443 --insecure
# 3. Restore its SSH host key, so it can decrypt its secrets (sops-nix), and reboot. sebastian logs in with SSH keys
#    but has no password yet (it is one of those secrets), so there is no sudo: root acts through the QEMU guest agent
#    instead, with virsh in the VM's virt-launcher pod. The key never appears on a command line:
#    a. Copy it into sebastian's home. The VM still has the host key of its first boot, not the pinned one, hence
#       the host key check left out this once:
#         sops decrypt --extract '["ssh_host_ed25519_key"]' secrets/file-ssh-host-key.sops.yaml \
#           | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null \
#               file.home.karlsen.fr 'umask 077; cat > ~/.ssh_host_ed25519_key.restore'
#    b. Install it as root and reboot (guest-exec runs with an empty PATH, hence the export):
#         s='export PATH=/run/current-system/sw/bin; K=/home/sebastian/.ssh_host_ed25519_key.restore;
#            install -m 600 $K /etc/ssh/ssh_host_ed25519_key &&
#            ssh-keygen -y -f $K > /etc/ssh/ssh_host_ed25519_key.pub && shred -u $K && systemctl reboot'
#         kubectl exec -n file "$(kubectl get pod -n file -l kubevirt.io=virt-launcher -o name)" -c compute -- \
#           virsh -c 'qemu+unix:///session?socket=/var/run/libvirt/virtqemud-sock' qemu-agent-command file_file \
#           "$(jq -nc --arg s "$s" '{execute: "guest-exec", arguments: {path: "/run/current-system/sw/bin/sh", arg: ["-c", $s]}}')"
#    c. Check: `ssh file.home.karlsen.fr` now passes the pinned host key check (modules/nixos/common/openssh.nix).
# 4. Format the data disk once, if it is new (a guest-exec as above, or sudo now that sebastian has his password):
#      mkfs.btrfs -L samsung_storage /dev/vdb    # then the shares' directories under /mnt/data_disk1 (./nfs.nix)
{
  imports = [
    "${modulesPath}/virtualisation/kubevirt.nix" # qemu guest, serial console, / by label (grows), system.build.image
    ./nfs.nix
    ./firewall.nix
    ../../modules/nixos/common
    ../../modules/nixos/server
  ];

  networking.hostName = "file";
  nixpkgs.hostPlatform = "x86_64-linux"; # No hardware-configuration.nix: the virtual hardware is kubevirt.nix's

  # Virtual disks have no SMART. smartctl stays (modules/nixos/server).
  services.smartd.enable = false;

  # No cloud-init (on in kubevirt.nix): everything is configured here, and the SSH host key restored by hand (above).
  # Its first boot would regenerate the host keys (its ssh module), and it touches passwords, users, resolv.conf and
  # the hostname, which NixOS manages; it also probes for a data source at every boot.
  services.cloud-init.enable = lib.mkForce false;

  # Zabbix's passive checks: inside the cluster, from the server's pod address (unmasqueraded), not its node's
  services.zabbixAgent.passiveSources = [ (import ../helios/lan.nix).clusterPods ];

  # BIOS boot with GRUB on /dev/vda (kubevirt.nix), not EFI/systemd-boot
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  # Bridge binding: the VM gets its pod's address by DHCP from virt-launcher, so it sees the NFS clients'
  # real addresses, which the exports rely on (masquerade would show them all as 10.0.2.1).
  # Matched by type, not MAC: the VM gets its pod's MAC (new on every start), the one Cilium sends the pod's traffic
  # to. A MAC pinned in the VirtualMachine would differ from it, and the VM would never see its inbound traffic.
  systemd.network.networks."10-pod" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "ipv4";
  };

  system.stateVersion = "26.05";
}
