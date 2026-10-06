{ config, self, ... }:

# Cloudflare: certificates (Let's Encrypt, DNS-01) and the public IP in DNS. They replace certbot and the
# cf-update cron job of the former Ansible role. The API token is a secret (secrets/helios.sops.yaml).
{
  sops.secrets.cloudflare-api-token.sopsFile = "${self}/secrets/helios.sops.yaml";

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
}
