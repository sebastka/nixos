{
  config,
  lib,
  pkgs,
  self,
  ...
}:

# DNS, from the former Ansible role (templates/etc/unbound, templates/etc/nsd, routers/dnssec.yaml):
# - Unbound: recursive resolver for the LAN (port 53, DNS over TLS on 853), DNSSEC, local overrides for the public
#   domains (to the cluster's ingress), ad blocking (OISD's RPZ list, fetched and refreshed by Unbound itself).
# - NSD: authoritative for home.karlsen.fr and 168.192.in-addr.arpa (from ./lan.nix), on 127.0.0.1:53530, for
#   Unbound only. Signed (DNSSEC) with the existing keys: their KSKs are Unbound's trust anchors.
let
  lan = import ./lan.nix;
  nsdAddress = "127.0.0.1";
  nsdPort = 53530;
  tlsDirectory = config.security.acme.certs."karlsen.fr".directory; # ./acme.nix

  # Public names served by the cluster's ingress, answered locally (no hairpin through the public IP)
  localOverrides = {
    "karlsen.fr" = {
      type = "transparent";
      names = [
        ""
        "auth"
        "autoconfig"
        "ca"
        "captcha"
        "git"
        "ldap"
        "mas"
        "matrix"
        "mta-sts"
        "openpgpkey"
        "www"
      ];
    };
    "karlsen.org" = {
      type = "transparent";
      names = [
        ""
        "www"
        "mta-sts"
      ];
    };
    "karlsen.app" = {
      type = "redirect"; # Every name
      names = [ "" ];
    };
  };
  fqdn = zone: name: if name == "" then "${zone}." else "${name}.${zone}.";

  # DNSSEC keys (ECDSAP256SHA256), public parts. The private parts are secrets (secrets/helios.sops.yaml).
  dnssecKeys = {
    "home.karlsen.fr" = {
      ksk = "home.karlsen.fr. IN DNSKEY 257 3 13 SOcfh2vJ5SbkI9mZLvu9FeIHFxSrndQycUtHH/u2/f8EWAKQX6JxV57ZKmTpGwZjNWmZ7aTiHuOWUm+UXH1MUA==";
      zsk = "home.karlsen.fr. IN DNSKEY 256 3 13 CbY0zq1iT3aSZS5m3act+xrdmrh67dT95GDNFffgT0rpSG+XrcMlobNQgsg1JrXniyRmzlFXYqK7YzgZ5MlAbQ==";
    };
    "168.192.in-addr.arpa" = {
      ksk = "168.192.in-addr.arpa. IN DNSKEY 257 3 13 mni35Wj1xLBrGknfIFUEgqBtByiSTFta3GfeUUwJMHZnS8L+yMDbJUZKx11q+6PVkc+AQFgWSMehxdfVQnrivA==";
      zsk = "168.192.in-addr.arpa. IN DNSKEY 256 3 13 MVtLTZSYhnl9UOxuEWGnsR1qa4vyXJPodx8EYx/K9Z57UMLGz5y37BzcxYPmNgnZziFsshyFz47p2vN7TqzT6A==";
    };
  };
  secretName = zone: role: "dnssec-${lib.replaceStrings [ "." ] [ "-" ] zone}-${role}";

  # Zone files from ./lan.nix. The serial follows the configuration (last commit), signatures are renewed weekly.
  soa = ''
    $TTL 86400
    @  IN  SOA  ns.${lan.domain}. hostmaster.karlsen.fr. ( ${toString self.lastModified} 7200 3600 1209600 3600 )
    @  IN  NS   ns.${lan.domain}.
  '';
  zones = {
    "home.karlsen.fr" = (
      ''
        $ORIGIN ${lan.domain}.
        ${soa}
        @   IN  A  ${lan.router}
        ns  IN  A  ${lan.router}
      ''
      + lib.concatStrings (lib.mapAttrsToList (name: host: "${name}  IN  A  ${host.ip}\n") lan.hosts)
      + "*.talmox.hera  IN  CNAME  talmox.hera\n"
    );
    "168.192.in-addr.arpa" = (
      ''
        $ORIGIN 168.192.in-addr.arpa.
        ${soa}
      ''
      + lib.concatStrings (
        lib.mapAttrsToList (
          name: host:
          let
            octets = lib.splitString "." host.ip;
          in
          "${lib.elemAt octets 3}.${lib.elemAt octets 2}  IN  PTR  ${name}.${lan.domain}.\n"
        ) lan.hosts
      )
    );
  };
in
{
  services.unbound = {
    enable = true;
    resolveLocalQueries = false; # resolved points to it (./network.nix)
    localControlSocketPath = "/run/unbound/unbound.ctl";
    settings = {
      server = {
        verbosity = 0;
        interface = [
          "127.0.0.1@53"
          "${lan.router}@53"
          "${lan.router}@853"
        ];
        ip-freebind = true; # Start before br0 has its address
        do-ip4 = true;
        do-ip6 = false;
        access-control = [
          "10.0.0.0/8 allow"
          "172.16.0.0/12 allow"
          "192.168.0.0/16 allow"
          "127.0.0.0/8 allow"
          "0.0.0.0/0 refuse"
        ];

        # Privacy and security
        hide-identity = true;
        hide-version = true;
        harden-glue = true;
        harden-dnssec-stripped = true;
        harden-referral-path = true;
        harden-algo-downgrade = true;
        use-caps-for-id = true;
        deny-any = true;
        do-not-query-localhost = false; # NSD on 127.0.0.1
        val-clean-additional = true;

        # DNS over TLS (port 853)
        tls-service-key = "${tlsDirectory}/key.pem";
        tls-service-pem = "${tlsDirectory}/fullchain.pem";

        # Performance
        num-threads = 2;
        msg-cache-slabs = 4;
        rrset-cache-slabs = 4;
        infra-cache-slabs = 4;
        key-cache-slabs = 4;
        msg-cache-size = "64m";
        rrset-cache-size = "128m";
        key-cache-size = "32m";
        neg-cache-size = "4m";
        prefetch = true;
        prefetch-key = true;
        minimal-responses = true;

        # Logging
        log-queries = false;
        log-replies = false;
        log-tag-queryreply = true;
        log-local-actions = true;
        log-servfail = true;

        # No private addresses in public answers (DNS rebinding)
        private-address = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "169.254.0.0/16"
          "fd00::/8"
          "fe80::/10"
        ];
        private-domain = (map (zone: "${zone}.") (lib.attrNames localOverrides)) ++ [ "${lan.domain}." ];

        module-config = ''"respip validator iterator"'';

        local-zone = (lib.mapAttrsToList (zone: o: ''"${zone}." ${o.type}'') localOverrides) ++ [
          ''"${lan.domain}." nodefault''
          ''"168.192.in-addr.arpa." nodefault''
        ];
        local-data = lib.concatLists (
          lib.mapAttrsToList (
            zone: o: map (name: ''"${fqdn zone name} IN A ${lan.vips.gatewayDefault}"'') o.names
          ) localOverrides
        );

        # The local zones are signed by NSD (below): their KSKs
        trust-anchor = map (zone: ''"${dnssecKeys.${zone}.ksk}"'') (lib.attrNames dnssecKeys);
      };

      stub-zone = map (zone: {
        name = "${zone}.";
        stub-addr = "${nsdAddress}@${toString nsdPort}";
        stub-prime = false;
        stub-first = false;
        stub-tls-upstream = false;
      }) (lib.attrNames zones);

      # Ad blocking: OISD (big), refreshed by Unbound following the list's SOA
      rpz = {
        name = "oisd";
        url = "https://big.oisd.nl/rpz";
        zonefile = "/var/lib/unbound/oisd.rpz";
        rpz-log = true;
        rpz-log-name = "oisd";
      };
    };
  };
  # The certificate (self-signed until Let's Encrypt's arrives, ./acme.nix) must exist
  systemd.services.unbound = {
    wants = [
      "acme-karlsen.fr.service"
      "network-online.target"
    ];
    after = [
      "acme-karlsen.fr.service"
      "network-online.target"
    ];
  };

  services.nsd = {
    enable = true;
    interfaces = [ nsdAddress ];
    port = nsdPort;
    ipv6 = false;
    hideVersion = true;
    serverCount = 1;
    extraConfig = ''
      server:
        hide-identity: yes
        minimal-responses: yes
        confine-to-zone: yes
        refuse-any: yes
    '';
    zones = lib.mapAttrs (_: data: { inherit data; }) zones; # Signed when NSD starts (below)
  };

  # Private DNSSEC keys, in the format ldns-signzone reads (<name>.private next to <name>.key)
  sops.secrets = lib.listToAttrs (
    lib.concatMap (
      zone:
      map
        (role: lib.nameValuePair (secretName zone role) { sopsFile = "${self}/secrets/helios.sops.yaml"; })
        [
          "ksk"
          "zsk"
        ]
    ) (lib.attrNames dnssecKeys)
  );
  sops.templates = lib.listToAttrs (
    lib.concatMap (
      zone:
      map
        (
          role:
          lib.nameValuePair "${zone}.${role}.private" {
            content = ''
              Private-key-format: v1.2
              Algorithm: 13 (ECDSAP256SHA256)
              PrivateKey: ${config.sops.placeholder.${secretName zone role}}
            '';
          }
        )
        [
          "ksk"
          "zsk"
        ]
    ) (lib.attrNames dnssecKeys)
  );

  # Sign the zones (60 days of validity) each time NSD starts (boot, zone changes, weekly below): in place, after the
  # module's pre-start script copied them to /var/lib/nsd/zones
  systemd.services.nsd.preStart = lib.mkAfter (
    ''
      keys=$(mktemp -d)
      trap 'rm -rf "$keys"' EXIT
      expiry=$(date -d '+60 days' '+%Y%m%d%H%M%S')
    ''
    + lib.concatStrings (
      lib.mapAttrsToList (zone: _: ''
        cp "${config.sops.templates."${zone}.ksk.private".path}" "$keys/${zone}.ksk.private"
        cp "${config.sops.templates."${zone}.zsk.private".path}" "$keys/${zone}.zsk.private"
        echo '${dnssecKeys.${zone}.ksk}' > "$keys/${zone}.ksk.key"
        echo '${dnssecKeys.${zone}.zsk}' > "$keys/${zone}.zsk.key"
        ${pkgs.ldns.examples}/bin/ldns-signzone -e "$expiry" -f "/var/lib/nsd/zones/${zone}.signed" \
          "/var/lib/nsd/zones/${zone}" "$keys/${zone}.ksk" "$keys/${zone}.zsk"
        mv "/var/lib/nsd/zones/${zone}.signed" "/var/lib/nsd/zones/${zone}"
      '') zones
    )
  );
  systemd.services.nsd-resign = {
    description = "Restart NSD, which re-signs its zones";
    serviceConfig.Type = "oneshot";
    script = "systemctl restart nsd.service";
  };
  systemd.timers.nsd-resign = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
