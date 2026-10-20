{ ... }:

# Interfaces (systemd-networkd, as on Debian): enp1s0 is the WAN (the ISP's DHCP), enp2s0-enp6s0 are bridged into br0,
# the LAN (192.168.0.0/16). IPv6 is off. From the former Ansible role (interfaces.yaml, templates/etc/systemd/network).
let
  lanPorts = {
    enp2s0 = "00:e0:67:2e:87:51";
    enp3s0 = "00:e0:67:2e:87:52";
    enp4s0 = "00:e0:67:2e:87:53";
    enp5s0 = "00:e0:67:2e:87:54";
    enp6s0 = "00:e0:67:2e:87:55";
  };
  localResolver = {
    DNS = "127.0.0.1"; # Unbound (./dns.nix)
    # Unbound validates (the local zones too, with their trust anchors). resolved would validate again from the root,
    # and reject home.karlsen.fr's answers: public karlsen.fr has no delegation to it ("no-signature").
    DNSSEC = false;
    DNSOverTLS = false;
    Domains = "home.karlsen.fr";
    # No name resolution by asking the whole network (mDNS's .local, Microsoft's LLMNR): helios is the LAN's DNS, which
    # knows every name (./lan.nix). The firewall let neither in, and LLMNR listened on the WAN too.
    MulticastDNS = false;
    LLMNR = false;
  };
in
{
  # The I211's (igb) RX rings overflow (rx_missed_errors) while the CPU wakes from deep C-states: larger rings.
  # Deep C-states allowed all the same, as on Debian since 2026-10-14, to run cooler: past C1E, 2-4% of WAN packets
  # are lost and downloads cap at ~260-450 Mbit/s (777 Mbit/s with intel_idle.max_cstate=2 in boot.kernelParams).
  systemd.network.links."10-igb" = {
    matchConfig.Driver = "igb";
    linkConfig = {
      # Only the first matching .link file applies: repeat 99-default.link's policies
      NamePolicy = "keep kernel database onboard slot path";
      AlternativeNamesPolicy = "database onboard slot path mac";
      MACAddressPolicy = "persistent";
      RxBufferSize = 4096; # The igb driver's maximum
    };
  };
  # boot.kernelParams = [ "intel_idle.max_cstate=2" ]; # Throughput over heat: see above

  systemd.network.netdevs."10-br0".netdevConfig = {
    Name = "br0";
    Kind = "bridge";
  };

  systemd.network.networks = {
    "10-wan" = {
      matchConfig.MACAddress = "00:e0:67:2e:87:50"; # enp1s0
      networkConfig = localResolver // {
        DHCP = "ipv4";
        LinkLocalAddressing = "no";
        IPv6AcceptRA = "no";
        # Keep the DHCP address (and lease) while networkd stops/restarts: the ISP more likely keeps the public IP
        KeepConfiguration = "dynamic-on-stop";
      };
      dhcpV4Config = {
        UseDNS = false;
        SendRelease = false;
      };
      # CAKE (smart queue management) on uploads: off. Ookla from zeus, 2026-10-19, at full speed (943 Mbit/s down,
      # 939 up, with ./port-latency.nix): 14 ms idle, 25 ms while uploading (little: the queue forms on this port, where
      # its fq_codel keeps latency low), but 158 ms (up to 327) while downloading: that bufferbloat is the ISP's queue,
      # for the downloads' CAKE below (wan-ingress-cake). Should uploads need it too: ~95% of the measured upload,
      # Ethernet's overhead (header, FCS, preamble, gap), fairness between LAN hosts behind the NAT (validated values).
      # cakeConfig = {
      #   Parent = "root";
      #   Bandwidth = "900M";
      #   OverheadBytes = 38;
      #   NAT = true;
      #   FlowIsolationMode = "dual-src-host";
      # };
    };

    "20-br0" = {
      matchConfig.Name = "br0";
      address = [ "192.168.0.1/16" ];
      networkConfig = localResolver // {
        DHCP = "no";
        LinkLocalAddressing = "no";
        IPv6AcceptRA = "no";
      };
      linkConfig.RequiredForOnline = "routable";
    };
  }
  // builtins.listToAttrs (
    map (port: {
      name = "30-${port}";
      value = {
        matchConfig.MACAddress = lanPorts.${port};
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };
    }) (builtins.attrNames lanPorts)
  );

  # Online once the LAN is up: don't wait for the WAN, which may be down while the LAN must still be served
  systemd.network.wait-online.extraArgs = [ "--interface=br0" ];

  # CAKE on the WAN's downloads, against their bufferbloat (158 ms while downloading, see 10-wan above): off, to try.
  # A queue only controls what leaves an interface, so the downloads are redirected (tc's ingress hook, before
  # nftables' and the flowtable) to an ifb device, and shaped as they leave it: just below the line (~95% of 943
  # Mbit/s), so the queue forms here, under CAKE, instead of at the ISP. Ethernet's overhead; nat and dual-dsthost:
  # fairness between LAN hosts (their address behind the NAT), "ingress" for its accounting of incoming traffic.
  # Costs ~5% of download speed and some CPU. To try: uncomment, and { pkgs, ... }: as this file's arguments; check
  # with tc -s qdisc show dev ifb4enp1s0, and Waveform's bufferbloat test. (Validated by evaluation, not run yet.)
  # systemd.services.wan-ingress-cake = {
  #   description = "CAKE on the WAN's downloads (ifb)";
  #   after = [ "sys-subsystem-net-devices-enp1s0.device" ];
  #   bindsTo = [ "sys-subsystem-net-devices-enp1s0.device" ];
  #   wantedBy = [ "multi-user.target" ];
  #   path = [ pkgs.iproute2 ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
  #   script = ''
  #     ip link add ifb4enp1s0 type ifb 2>/dev/null || true
  #     ip link set ifb4enp1s0 up
  #     tc qdisc replace dev enp1s0 handle ffff: ingress
  #     tc filter replace dev enp1s0 parent ffff: matchall action mirred egress redirect dev ifb4enp1s0
  #     tc qdisc replace dev ifb4enp1s0 root cake bandwidth 900mbit overhead 38 nat dual-dsthost ingress
  #   '';
  #   # Undone when stopped: the downloads unshaped again
  #   preStop = ''
  #     tc qdisc del dev enp1s0 ingress 2>/dev/null || true
  #     ip link del ifb4enp1s0 2>/dev/null || true
  #   '';
  # };

  # Same DNS for the router itself: Unbound, the local zone
  services.resolved.settings.Resolve = localResolver;

  # Routing (IPv4 only), from the former Ansible role (routers/sysctlconf.yaml)
  boot.kernelModules = [ "nf_conntrack" ]; # Before sysctl, so net.netfilter.* exist when applied
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.netfilter.nf_conntrack_tcp_loose" = 0; # No mid-stream TCP pickup: non-SYN packets without conntrack entry are invalid
    "net.netfilter.nf_conntrack_tcp_timeout_established" = 86400; # 1 day instead of 5
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0; # all.* is ORed with the per-interface value
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.br0.accept_redirects" = 0;
    "net.ipv6.conf.enp1s0.accept_redirects" = 0;
    "net.ipv4.conf.all.rp_filter" = 1; # Strict reverse path filtering: drop spoofed sources
  };
}
