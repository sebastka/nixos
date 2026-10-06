{ ... }:

# Firewall and NAT of the router, from the former Ansible role (templates/etc/nftables.conf/routers.conf).
# Interfaces are matched by name (iifname/oifname, flowtable and ingress devices): nftables loads before networkd
# creates br0. The NixOS firewall is replaced by these tables.
let
  lan = import ./lan.nix;
  wan = "enp1s0";
  router = lan.router;
  lanPhysicalDevices = "192.168.0.0/24";
  lanVirtualMachines = "192.168.1.0/24";
  # Forced to use the local resolver. TODO: tvboks is 192.168.0.11 in DHCP (./lan.nix), Ansible had 192.168.0.5 here
  tvbox = "192.168.0.5";
  inherit (lan.vips) gatewayDefault delugeTorrent theloungeIdentd;

  # New TCP connections must start with a bare SYN (also drops SYN+FIN, SYN+RST, null flags: scans, mid-stream pickup)
  conntrackFirst = ''
    ct state vmap { invalid : drop, established : accept, related : accept }
    ct state new tcp flags & (fin|syn|rst|ack) != syn drop
  '';
in
{
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;
    # The build-time check runs in a sandbox without these interfaces: the WAN ingress hook on lo, and the flowtable
    # (which lo can't be part of) without devices nor its rule
    preCheckRuleset = ''
      sed -i '/devices = { "${wan}", "br0" };/d; /flow add @fastpath/d; s/"${wan}"/"lo"/g' ruleset.conf
    '';

    tables.wan = {
      family = "netdev";
      content = ''
        # Volatile: nothing adds to them yet
        set blackhole4 { type ipv4_addr; flags interval; auto-merge; }
        set blackhole6 { type ipv6_addr; flags interval; auto-merge; }

        set bogons4 {
          type ipv4_addr; flags interval;
          elements = { 0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8, 169.254.0.0/16,
                       172.16.0.0/12, 192.0.0.0/24, 192.0.2.0/24, 192.168.0.0/16,
                       198.18.0.0/15, 198.51.100.0/24, 203.0.113.0/24, 224.0.0.0/3 }
        }
        # Reserved ranges inside global unicast (2000::/3): Teredo, ORCHID, documentation (x2), 6to4
        set bogons6 {
          type ipv6_addr; flags interval;
          elements = { 2001::/32, 2001:10::/28, 2001:db8::/32, 2002::/16, 3fff::/20 }
        }

        # Before conntrack and DNAT: dropped packets never create conntrack entries
        chain ingress {
          type filter hook ingress devices = { "${wan}" } priority -500;
          udp sport bootps udp dport bootpc accept  # ISP's DHCP (ingress runs before networkd's DHCP socket)
          ip saddr @bogons4 drop
          ip6 saddr != { ::/128, fe80::/10, 2000::/3 } drop  # Only global unicast, link-local and unspecified
          ip6 saddr @bogons6 drop
          ip saddr @blackhole4 drop
          ip6 saddr @blackhole6 drop
        }
      '';
    };

    tables.nat = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;

          # Force DNS requests to the local resolver
          iifname "br0" ip saddr ${tvbox} ip daddr != ${lanPhysicalDevices} meta l4proto { tcp, udp } th dport domain dnat to ${router}:53
          iifname "br0" ip saddr ${tvbox} ip daddr != ${lanPhysicalDevices} meta l4proto { tcp, udp } th dport domain-s dnat to ${router}:853

          # Port forwards to the homelab
          iifname "${wan}" tcp dport { http, https, ssh } dnat to ${gatewayDefault}
          iifname "${wan}" meta l4proto { tcp, udp } th dport 6881 dnat to ${delugeTorrent}
          iifname "${wan}" tcp dport auth dnat to ${theloungeIdentd}

          # Hairpin NAT: LAN clients reaching our (dynamic) public IP get the same DNAT as the WAN
          iifname "br0" fib daddr type local ip daddr != 192.168.0.0/16 tcp dport { http, https, ssh } dnat to ${gatewayDefault}
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          iifname "br0" oifname "${wan}" masquerade
          iifname "br0" oifname "br0" ct status dnat masquerade  # Hairpin NAT: replies go back through the router
        }
      '';
    };

    tables.filter = {
      family = "ip";
      content = ''
        # Software fastpath: once a flow has seen both directions, its packets skip the forward chain and NAT hooks
        flowtable fastpath {
          hook ingress priority filter;
          devices = { "${wan}", "br0" };
        }

        # Per-source rate of new WAN connections (token bucket per IP, forgotten after 1 minute idle)
        set wan_new4 { type ipv4_addr; flags dynamic, timeout; timeout 1m; size 65536; }
        # Per-source concurrent SSH connections from the WAN
        set wan_ssh4 { type ipv4_addr; flags dynamic; size 65536; }

        chain input {
          type filter hook input priority filter; policy drop;
          iif lo accept
          ${conntrackFirst}

          # WAN (destination-unreachable and time-exceeded are covered by ct state related)
          iifname "${wan}" icmp type echo-request limit rate 5/second accept

          # LAN
          iifname "br0" ip protocol icmp accept
          iifname "br0" udp sport bootpc ip daddr { ${router}, 255.255.255.255 } udp dport bootps accept  # Kea
          iifname "br0" ip saddr ${lanVirtualMachines} ip daddr ${router} tcp dport { zabbix-agent, 8080 } accept  # Zabbix, Stork
          iifname "br0" ip saddr ${lanPhysicalDevices} ip daddr ${router} tcp dport ssh accept
          iifname "br0" ip daddr ${router} tcp dport { domain, domain-s } accept  # Unbound, DNS over TLS too
          iifname "br0" ip daddr ${router} udp dport domain accept
        }

        chain forward {
          type filter hook forward priority filter; policy drop;
          meta l4proto { tcp, udp } flow add @fastpath  # Offload established flows (before the vmap, which would accept them)
          ${conntrackFirst}

          # LAN <-> LAN and LAN -> WAN
          iifname "br0" oifname "${wan}" accept
          iifname "br0" oifname "br0" accept

          # WAN -> homelab: per-source limits first (drops: nft list chain ip filter forward)
          iifname "${wan}" ct state new update @wan_new4 { ip saddr limit rate over 50/second burst 100 packets } counter drop
          iifname "${wan}" ct state new tcp dport ssh add @wan_ssh4 { ip saddr ct count over 5 } counter drop

          # WAN -> homelab (port forwards above)
          iifname "${wan}" ip daddr ${gatewayDefault} tcp dport { http, https, ssh } accept
          iifname "${wan}" ip daddr ${delugeTorrent} meta l4proto { tcp, udp } th dport 6881 accept
          iifname "${wan}" ip daddr ${theloungeIdentd} tcp dport auth accept
        }

        chain output {
          type filter hook output priority filter; policy accept;
        }
      '';
    };

    tables.nat6 = {
      family = "ip6";
      content = ''
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          iifname "br0" oifname "${wan}" masquerade
        }
      '';
    };

    tables.filter6 = {
      family = "ip6";
      content = ''
        chain input {
          type filter hook input priority filter; policy drop;
          iif lo accept
          ${conntrackFirst}

          # WAN (destination-unreachable, packet-too-big, time-exceeded are covered by ct state related)
          iifname "${wan}" icmpv6 type echo-request limit rate 5/second accept
          # Neighbor discovery is link-local only (RFC 4861): hop limit 255, router advertisements from link-local
          iifname "${wan}" icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert } ip6 hoplimit 255 accept
          iifname "${wan}" icmpv6 type nd-router-advert ip6 saddr fe80::/10 ip6 hoplimit 255 accept

          iifname "br0" meta l4proto ipv6-icmp accept
        }

        chain forward {
          type filter hook forward priority filter; policy drop;
          ${conntrackFirst}
          iifname "br0" oifname "${wan}" accept
        }

        chain output {
          type filter hook output priority filter; policy accept;
        }
      '';
    };
  };
}
