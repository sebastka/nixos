{ config, ... }:

# Firewall of file, as the other servers' (hosts/hermes/firewall.nix): nftables, the NixOS firewall replaced, so
# nothing is opened implicitly (e.g. by services' openFirewall). Sources are the clients' real addresses: the Service
# in front of the VM keeps them (externalTrafficPolicy: Local), and pods reach it unmasqueraded.
let
  lan = import ../helios/lan.nix;
  lanPhysicalDevices = "192.168.0.0/24";
  zabbixSources = builtins.concatStringsSep ", " config.services.zabbixAgent.passiveSources;
in
{
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;

    tables.filter = {
      family = "ip";
      content = ''
        chain input {
          type filter hook input priority filter; policy drop;
          iif lo accept
          ct state invalid drop
          ct state { established, related } accept
          iif != lo ip protocol icmp limit rate 5/second accept
          udp sport bootps udp dport bootpc accept  # Its pod's address, by DHCP from virt-launcher
          ip saddr ${lanPhysicalDevices} tcp dport ssh accept
          # NFS (./nfs.nix: the exports narrow it per share): the LAN and the Talos nodes, and pods (Longhorn's backups)
          ip saddr { 192.168.0.0/16, ${lan.clusterPods} } tcp dport nfs accept
          ip saddr { ${zabbixSources} } tcp dport 10050 accept  # Zabbix agent (modules/nixos/server)
        }
        chain forward {
          type filter hook forward priority filter; policy drop;
        }
        chain output {
          type filter hook output priority filter; policy accept;
        }
      '';
    };

    # No IPv6: the cluster's pod network is IPv4 only. Loopback is allowed.
    tables.filter6 = {
      family = "ip6";
      content = ''
        chain input {
          type filter hook input priority filter; policy drop;
          iif lo accept
        }
        chain forward {
          type filter hook forward priority filter; policy drop;
        }
        chain output {
          type filter hook output priority filter; policy drop;
          oif lo accept
        }
      '';
    };
  };
}
