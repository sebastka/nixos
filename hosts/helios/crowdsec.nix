{ config, ... }:

# CrowdSec's firewall bouncer: the homelab's decisions (its agents: Envoy, the apps; and the community blocklist)
# dropped at the WAN, for helios and every port forward alike. Only the bouncer: helios itself serves nothing on the WAN
# (its SSH is LAN-only, the rest is forwarded), so no agent here.
#
# Its set is crowdsec4 (IPv4 only: no IPv6 from the ISP), in the netdev table wan (./firewall.nix): the ingress hook
# drops its addresses before conntrack and DNAT. The bouncer only fills it ("set-only"), with each decision's duration
# as the element's timeout. Not the module's own tables (createRulesets): their chain is on the input hook, which
# forwarded traffic skips. A ruleset reload (nftables.service) empties the set: the bouncer restarts with it and
# refills it.
#
# The local API: the homelab's (sebastka/homelab: k8s/infrastructure/controllers/crowdsec), through its internal
# gateway, on the LAN. Its API key, created in the LAPI's pod, in secrets/helios.sops.yaml:
#   kubectl -n crowdsec exec deploy/crowdsec-lapi -- cscli bouncers add helios-firewall -o raw
#
#   journalctl -u crowdsec-firewall-bouncer             Its decisions' updates
#   nft list set netdev wan crowdsec4                   The banned addresses, with their remaining time
#   nft list chain netdev wan ingress                   Their drops (counter)
{
  sops.secrets.crowdsec-bouncer-api-key.sopsFile = ../../secrets/helios.sops.yaml;

  services.crowdsec-firewall-bouncer = {
    enable = true;
    createRulesets = false; # ./firewall.nix
    secrets.apiKeyPath = config.sops.secrets.crowdsec-bouncer-api-key.path;
    settings = {
      api_url = "https://crowdsec-lapi.talmox.hera.home.karlsen.fr/";
      blacklists_ipv4 = "crowdsec4";
      nftables = {
        ipv4 = {
          table = "wan";
          set-only = true;
        };
        # No IPv6 from the ISP. (Both in table wan wouldn't evaluate: the module names its own tables after both
        # settings, even unused.)
        ipv6.enabled = false;
        # With IPv6 from the ISP: its own netdev table, as the module requires (wan6, with set crowdsec6 and its drop
        # in ./firewall.nix), instead of the line above, and blacklists_ipv6 = "crowdsec6" next to blacklists_ipv4
        # ipv6 = {
        #   table = "wan6";
        #   set-only = true;
        # };
      };
    };
  };

  # The cluster boots after the router (power cut) or may be down: retry until its API answers, instead of failing once
  # for good (the module sets no Restart)
  systemd.services.crowdsec-firewall-bouncer = {
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "unbound.service" # Its API's name
    ];
    startLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
}
