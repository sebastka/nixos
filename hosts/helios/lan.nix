# The LAN (192.168.0.0/16) as helios serves it: each host's DHCP reservation (./dhcp.nix, when it has a MAC
# address), and its A and PTR records in home.karlsen.fr and 168.192.in-addr.arpa (./dns.nix). wakeMacs: other network
# cards of a host, with the same reservation (its IP), which `wake <host>` also wakes (./wake.nix).
# Names are relative to home.karlsen.fr.
{
  domain = "home.karlsen.fr";
  router = "192.168.0.1"; # br0, ./network.nix

  hosts = {
    # 192.168.0.0/24 - Physical machines
    helios = {
      ip = "192.168.0.1";
      mac = "00:e0:67:2e:87:51";
    }; # Router (enp2s0, in br0)
    harmonia = {
      ip = "192.168.0.2";
      mac = "d4:d6:df:0a:a6:1b";
    };
    hermes = {
      ip = "192.168.0.10";
      mac = "dc:a6:32:e7:41:c9";
    };
    googletv = {
      ip = "192.168.0.11";
      mac = "b4:23:a2:42:88:44";
    };
    zeus = {
      ip = "192.168.0.15";
      # mac = "18:c0:4d:85:cd:2f"; # Intel I211 1 GbE
      mac = "18:c0:4d:85:cd:2e"; # Aquantia AQC107 10 GbE
      wakeMacs = [ "18:c0:4d:85:cd:2f" ];
    };
    atlas = {
      ip = "192.168.0.20";
      mac = "e0:db:55:25:b0:4c";
    };
    atlas-idrac = {
      ip = "192.168.0.21";
      mac = "e0:db:55:25:b0:4e";
    };
    chronos = {
      ip = "192.168.0.30";
    };
    hera = {
      ip = "192.168.0.40";
      mac = "88:ae:dd:68:ab:e8";
    };
    hestia = {
      ip = "192.168.0.50";
      mac = "48:21:0b:7d:f6:25";
    };
    dike = {
      ip = "192.168.0.60";
      mac = "48:21:0b:7d:f4:73";
    };

    # Wireless devices
    rax80 = {
      ip = "192.168.0.100";
      mac = "10:0c:6b:59:c2:92";
    };
    boreas = {
      ip = "192.168.0.101";
      mac = "c8:89:f3:b7:69:2d";
    };
    geras = {
      ip = "192.168.0.102";
      mac = "84:c5:a6:93:15:2a";
    };
    sebastka-caiman = {
      ip = "192.168.0.110";
      mac = "20:f0:94:03:23:8d";
    };
    sk-g990b = {
      ip = "192.168.0.111";
      mac = "f4:02:28:d8:a1:7d";
    };

    # 192.168.1.0/24 - Virtual machines
    "db01.hera" = {
      ip = "192.168.1.11";
      mac = "bc:24:11:36:0c:75";
    };
    "db02.hera" = {
      ip = "192.168.1.12";
      mac = "bc:24:11:f5:db:10";
    };
    "file01.hera" = {
      ip = "192.168.1.20";
      mac = "bc:24:11:82:e0:a3";
    };
    "file.atlas" = {
      ip = "192.168.1.100";
      mac = "f6:c0:b4:cb:36:3e";
    };
    "torrent.atlas" = {
      ip = "192.168.1.101";
      mac = "a6:80:fb:4b:01:2f";
    };
    "xp.atlas" = {
      ip = "192.168.1.105";
      mac = "92:b6:40:06:70:e6";
    };
    "t01.hera" = {
      ip = "192.168.1.201";
      mac = "bc:24:11:10:fe:09";
    };

    # 192.168.2.0/24 - Cilium IP pool (LoadBalancer IPs of the cluster)
    "talmox.hera" = {
      ip = "192.168.2.1";
    }; # *.talmox.hera too (./dns.nix)
  };

  # Cluster services, also the targets of port forwards (./firewall.nix)
  vips = {
    gatewayInternal = "192.168.2.1";
    gatewayDefault = "192.168.2.2"; # Ingress for the public domains (./dns.nix, local overrides)
    delugeTorrent = "192.168.2.10";
    theloungeIdentd = "192.168.2.11";
    zabbixServer = "192.168.2.12";
    syncthing = "192.168.2.14"; # Sync connections (TCP and QUIC 22000), forwarded from the WAN
  };
}
