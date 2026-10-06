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
    DNSSEC = true;
    DNSOverTLS = false;
    Domains = "home.karlsen.fr";
  };
in
{
  # The I211's (igb) RX rings overflow (rx_missed_errors) while the CPU wakes from deep C-states: larger rings,
  # and no C-state deeper than C2.
  systemd.network.links."10-igb" = {
    matchConfig.Driver = "igb";
    linkConfig = {
      # Only the first matching .link file applies: repeat 99-default.link's policies
      NamePolicy = "keep kernel database onboard slot path";
      AlternativeNamesPolicy = "database onboard slot path mac";
      MACAddressPolicy = "persistent";
      RxBufferSize = 4096;
    };
  };
  boot.kernelParams = [ "intel_idle.max_cstate=2" ];

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

  # Same DNS for the router itself: Unbound, the local zone, mDNS
  services.resolved.settings.Resolve = localResolver // {
    MulticastDNS = "yes";
  };

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
