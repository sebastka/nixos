# Public names Unbound answers locally (./dns.nix, and the installer's ./installer.nix): no hairpin through the
# public IP.
let
  lan = import ./lan.nix;
in
{
  # Names served by the cluster's ingress (lan.vips.gatewayDefault)
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

  # Names answered with a cluster service's own LoadBalancer rather than the ingress (their zones above are
  # transparent: no local-zone of their own needed)
  serviceOverrides = {
    "sync.karlsen.fr" = lan.vips.syncthing; # Syncthing (TCP and QUIC 22000)
  };

  fqdn = zone: name: if name == "" then "${zone}." else "${name}.${zone}.";
}
