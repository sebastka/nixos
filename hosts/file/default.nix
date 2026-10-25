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
# 2. Upload it into the VM's root DataVolume (it waits for an upload, see the homelab's manifests):
#      virtctl image-upload dv file-root -n file --no-create --image-path=result/*.qcow2 \
#        --uploadproxy-url=https://127.0.0.1:18443 --insecure   # after a port-forward to cdi-uploadproxy
# 3. Start the VM, then restore its SSH host key, so it can decrypt its secrets (sops-nix), and redeploy:
#      sops decrypt --extract '["ssh_host_ed25519_key"]' secrets/file-ssh-host-key.sops.yaml \
#        | ssh file.home.karlsen.fr 'sudo install -m 600 /dev/stdin /etc/ssh/ssh_host_ed25519_key'
#      ssh file.home.karlsen.fr 'sudo reboot'
#    Until then, sebastian has no password (it's a secret) but logs in with SSH keys.
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
  # The MAC is pinned in the VirtualMachine (locally administered: 02:...), as KubeVirt would pick
  # another one on every start.
  systemd.network.networks."10-pod" = {
    matchConfig.MACAddress = "02:6b:76:00:f0:02";
    networkConfig.DHCP = "ipv4";
  };

  system.stateVersion = "26.05";
}
