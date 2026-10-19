{
  lib,
  modulesPath,
  ...
}:

# helios's installer: the NixOS live ISO, as the router. It routes the LAN while helios's own disk is wiped and
# installed, from another machine over SSH (no Yubikey on helios needed):
#   nix build .#nixosConfigurations.helios-installer.config.system.build.isoImage   (on zeus)
#   dd it to a USB stick, boot helios from it (WAN cable in enp1s0, as usual), then from geras:
#   bin/install-host helios nixos@192.168.0.1
# The same network, firewall and DHCP as helios (./network.nix, ./firewall.nix, ./dhcp.nix), from RAM. DNS without
# secrets: the live ISO can't decrypt helios's (no host key), so a plainer Unbound than ./dns.nix: the local names
# unsigned, no DNS over TLS (its certificate), no ad blocking. No Cloudflare record updates (./acme.nix) either.
let
  lan = import ./lan.nix;
  inherit (import ./dns-overrides.nix) localOverrides serviceOverrides fqdn;
  reverse =
    ip:
    let
      octets = lib.splitString "." ip;
    in
    "${lib.elemAt octets 3}.${lib.elemAt octets 2}.168.192.in-addr.arpa.";
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./network.nix
    ./firewall.nix
    ./dhcp.nix
  ];

  networking.hostName = "helios";
  # As on helios (modules/nixos/server): networkd only. Not the live ISO's NetworkManager and Wi-Fi.
  networking.useDHCP = false;
  networking.useNetworkd = true;
  networking.networkmanager.enable = lib.mkForce false;
  networking.wireless.enable = lib.mkForce false;

  # SSH from geras, by key (the Yubikey's, as on every host): the live ISO's sshd doesn't start by itself
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
  users.users.nixos.openssh.authorizedKeys.keyFiles = [
    ../../users/sebastian/keys/private.id_ed25519_gpg.pub
  ];

  services.unbound = {
    enable = true;
    resolveLocalQueries = false; # resolved points to it (./network.nix)
    settings.server = {
      interface = [
        "127.0.0.1@53"
        "${lan.router}@53"
      ];
      ip-freebind = true; # Start before br0 has its address
      do-ip6 = false;
      access-control = [
        "192.168.0.0/16 allow"
        "127.0.0.0/8 allow"
        "0.0.0.0/0 refuse"
      ];
      private-domain = (map (zone: "${zone}.") (lib.attrNames localOverrides)) ++ [ "${lan.domain}." ];

      # The local zones, unsigned, from ./lan.nix (./dns.nix: signed, served by NSD)
      local-zone = (lib.mapAttrsToList (zone: o: ''"${zone}." ${o.type}'') localOverrides) ++ [
        ''"${lan.domain}." static''
        ''"talmox.hera.${lan.domain}." redirect'' # *.talmox.hera too
        ''"168.192.in-addr.arpa." static''
      ];
      local-data = [
        ''"${lan.domain}. IN A ${lan.router}"''
        ''"ns.${lan.domain}. IN A ${lan.router}"''
      ]
      ++ lib.mapAttrsToList (name: host: ''"${name}.${lan.domain}. IN A ${host.ip}"'') lan.hosts
      ++ lib.mapAttrsToList (name: host: ''"${reverse host.ip} IN PTR ${name}.${lan.domain}."'') lan.hosts
      ++ lib.concatLists (
        lib.mapAttrsToList (
          zone: o: map (name: ''"${fqdn zone name} IN A ${lan.vips.gatewayDefault}"'') o.names
        ) localOverrides
      )
      ++ lib.mapAttrsToList (name: ip: ''"${name}. IN A ${ip}"'') serviceOverrides;
    };
  };
}
