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
      # Router: Protectli FW6. Intel Core i5-8250U (UHD Graphics 620), 16 GB, 120 GB mSATA, 6 Intel I211 1 GbE ports
      ip = "192.168.0.1";
      # mac = "00:e0:67:2e:87:50"; # enp1s0: WAN
      mac = "00:e0:67:2e:87:51"; # enp2s0: LAN (br0)
      # mac = "00:e0:67:2e:87:52"; # enp3s0: LAN (br0)
      # mac = "00:e0:67:2e:87:53"; # enp4s0: LAN (br0)
      # mac = "00:e0:67:2e:87:54"; # enp5s0: LAN (br0)
      # mac = "00:e0:67:2e:87:55"; # enp6s0: LAN (br0)
    };
    harmonia = {
      # Switch: TP-Link ES210X-M2, with static LAGs to hestia (ports 3+4) and dike (ports 5+6)
      ip = "192.168.0.2";
      mac = "d4:d6:df:0a:a6:1b";
    };
    hermes = {
      # Server: Raspberry Pi 4 Model B (Rev 1.4), 8 GB, 116 GB SD card
      ip = "192.168.0.10";
      mac = "dc:a6:32:e7:41:c9";
    };
    googletv = {
      # TV box: Google TV Streamer (4K)
      ip = "192.168.0.11";
      mac = "b4:23:a2:42:88:44"; # Ethernet
      # mac = "10:0c:6b:59:c2:91"; # WiFi: the same IP
      wakeMacs = [ "10:0c:6b:59:c2:91" ];
    };
    zeus = {
      # Desktop (Windows and NixOS): Gigabyte X570 AORUS XTREME. AMD Ryzen 9 5950X, Radeon RX 6800 XT, 32 GB, Samsung 980 PRO 500 GB and 2 TB (Windows), 970 EVO Plus 500 GB (NixOS)
      ip = "192.168.0.15";
      # mac = "18:c0:4d:85:cd:2f"; # Intel I211 1 GbE
      mac = "18:c0:4d:85:cd:2e"; # Aquantia AQC107 10 GbE
      wakeMacs = [ "18:c0:4d:85:cd:2f" ];
    };
    atlas = {
      # Server: Dell PowerEdge T420. 2 Intel Xeon E5-2407 (4 cores, 2.2 GHz), 128 GB DDR3, PERC H710 RAID controller, 8 3.5" bays, 2 Intel NICs, iDRAC 7 Enterprise (atlas-idrac)
      ip = "192.168.0.20";
      mac = "e0:db:55:25:b0:4c";
    };
    atlas-idrac = {
      # atlas's iDRAC (remote management)
      ip = "192.168.0.21";
      mac = "e0:db:55:25:b0:4e";
    };
    chronos = {
      # Future NAS: no hardware yet, DNS only
      ip = "192.168.0.30";
    };
    hera = {
      # Proxmox host: ASUS NUC 15 Pro+ (NUC15CRSU9). Intel Core Ultra 9 285H (Arc graphics), 96 GB, Samsung 9100 PRO 4 TB, Corsair MP600 Micro 1 TB, Intel I226-V 2.5 GbE
      ip = "192.168.0.40";
      mac = "88:ae:dd:68:ab:e8";
    };
    # Talos node (talmox): ASUS NUC 16 Pro (RNUC16GDKU760002). Intel Core Ultra 7 356H (Intel Graphics), Samsung 990 PRO 1 TB, 2 Intel I226-V 2.5 GbE bonded (harmonia ports 3+4)
    hestia = {
      ip = "192.168.0.50";
      mac = "48:21:0b:7d:f6:25";
    };
    # Talos node (talmox): ASUS NUC 16 Pro (RNUC16GDKU760002). Intel Core Ultra 7 356H (Intel Graphics), Samsung 980 250 GB, 2 Intel I226-V 2.5 GbE bonded (harmonia ports 5+6)
    dike = {
      ip = "192.168.0.60";
      mac = "48:21:0b:7d:f4:73";
    };

    # Wireless devices
    rax80 = {
      # Wi-Fi access point: Netgear Nighthawk RAX80 (Wi-Fi 6)
      ip = "192.168.0.100";
      mac = "10:0c:6b:59:c2:92";
    };
    boreas = {
      # Laptop: MacBook Pro 14" (2021), Apple M1 Pro, 16 GB
      ip = "192.168.0.101";
      mac = "c8:89:f3:b7:69:2d";
    };
    geras = {
      # Laptop: Dell XPS 15 7590. Intel Core i7-9750H (UHD Graphics 630), NVIDIA GTX 1650, 16 GB, Samsung PM981a 512 GB
      ip = "192.168.0.102";
      mac = "84:c5:a6:93:15:2a";
    };
    sebastka-grizzly = {
      # Phone: Google Pixel 11 Pro (codename grizzly)
      ip = "192.168.0.110";
      mac = "b0:9c:b2:f1:6b:29";
    };
    sebastka-caiman = {
      # Phone: Google Pixel 9 Pro (codename caiman)
      ip = "192.168.0.111";
      mac = "20:f0:94:03:23:8d";
    };
    sk-g990b = {
      # Phone: Samsung Galaxy S21 FE (SM-G990B)
      ip = "192.168.0.112";
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

  # The cluster's nodes (talmox, hosts above): the source of its pods' connections to helios (Cilium masquerades them
  # to their node's IP), e.g. Zabbix's and Stork's servers (./firewall.nix, ./stork.nix, modules/nixos/server)
  clusterNodes = [
    "hestia"
    "dike"
    "t01.hera"
  ];

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
