{ config, lib, ... }:

# Cloudflare: certificates (Let's Encrypt, DNS-01) and the public IP in DNS. They replace certbot and the
# cf-update cron job of the former Ansible role. The API token is a secret (secrets/helios.sops.yaml).
{
  sops.secrets.cloudflare-api-token.sopsFile = ../../secrets/helios.sops.yaml;

  # karlsen.fr, *.karlsen.fr and *.home.karlsen.fr: DNS over TLS (Unbound, ./dns.nix)
  security.acme = {
    acceptTerms = true;
    defaults.email = "hostmaster@karlsen.fr";
    certs."karlsen.fr" = {
      extraDomainNames = [
        "*.karlsen.fr"
        "*.home.karlsen.fr"
      ];
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53"; # Not Unbound: it answers karlsen.fr names locally
      credentialFiles.CLOUDFLARE_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-api-token.path;
      group = "unbound";
      reloadServices = [ "unbound.service" ];
    };
  };

  # A records of the domains served from home: the public IP (WAN, by DHCP from the ISP)
  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cloudflare-api-token.path;
    domains = [
      "bwdb.info"
      "karlsen.app"
      "karlsen.fr"
      "karlsen.org"
      "spkag.com"
    ];
    ipv4 = true;
    ipv6 = false;
    proxied = false;
  };
  # At boot, only once the WAN has its address and route (the ISP's DHCP): without it the public IP can't be looked up
  # (the unit would fail until its next run). Wanted, not required: if the WAN stays down, it still runs (and fails)
  # after the wait's timeout, as before.
  systemd.services.cloudflare-dyndns = {
    wants = [ "wan-online.service" ];
    after = [ "wan-online.service" ];
  };
  # Not systemd-networkd-wait-online@enp1s0: that one is ordered before network-online.target, which Kea and Unbound
  # wait for, so the LAN would get no DHCP nor DNS until the WAN is up (network-online.target waits for the LAN only,
  # ./network.nix). This one delays only what wants it.
  systemd.services.wan-online = {
    description = "Wait for the WAN (enp1s0) to be routable";
    after = [ "systemd-networkd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.escapeShellArgs [
        "${config.systemd.package}/lib/systemd/systemd-networkd-wait-online"
        "--interface=enp1s0:routable"
        "--timeout=120"
      ];
    };
  };
}
