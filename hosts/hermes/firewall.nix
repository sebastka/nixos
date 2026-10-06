{ ... }:

# Firewall of hermes, from the former Ansible role (/etc/nftables.conf on Debian), without Tailscale.
# The NixOS firewall is replaced by these tables: nothing is opened implicitly (e.g. by services' openFirewall).
let
  lanPhysicalDevices = "192.168.0.0/24";
  zabbixServer = "192.168.2.12"; # Zabbix server VIP (cluster)
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
          ip saddr ${lanPhysicalDevices} tcp dport ssh accept
          ip saddr ${zabbixServer} tcp dport 10050 accept # Zabbix agent
        }
        chain forward {
          type filter hook forward priority filter; policy drop;
        }
        chain output {
          type filter hook output priority filter; policy accept;
        }
      '';
    };

    # No IPv6, as on Debian. Loopback is allowed (Debian's ruleset dropped it too).
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
