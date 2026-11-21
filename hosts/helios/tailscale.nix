{ config, ... }:

# The tailnet's subnet router for the home LAN (192.168.0.0/16), on the router itself rather than in the cluster: the LAN
# stays reachable from the tailnet while the cluster is down. Formerly the Tailscale operator's Connector on talmox
# (sebastka/homelab: k8s/infrastructure/network/tailscale).
#
# Joins the tailnet as tag:router with an OAuth client of its own (sebastka/homelab: tofu-tailscale/oauth_clients.tf,
# the auth_keys scope, tag:router only), whose secret is tailscale-oauth-client-secret in secrets/helios.sops.yaml:
#   cd ../homelab/tofu-tailscale && tofu output -raw helios_oauth_client_secret   # then: sops edit secrets/helios.sops.yaml
# The route is approved by the policy (tofu-tailscale/policy/autoApprovers.hujson); who reaches the LAN, by its grants.
#
# Its firewall rules (input from the tailnet, forwarding into the LAN, NAT) are in ./firewall.nix: tailscaled doesn't
# touch netfilter (--netfilter-mode=off), so its forwards are only what ./firewall.nix allows.
{
  sops.secrets.tailscale-oauth-client-secret.sopsFile = ../../secrets/helios.sops.yaml;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server"; # IP forwarding (already on: a router), loose reverse path filtering
    # An OAuth client's secret as auth key: a device of its own, tagged (--advertise-tags), not expiring
    authKeyFile = config.sops.secrets.tailscale-oauth-client-secret.path;
    authKeyParameters = {
      ephemeral = false;
      preauthorized = true;
    };
    extraUpFlags = [
      "--advertise-tags=tag:router"
      "--advertise-routes=192.168.0.0/16"
      "--accept-dns=false" # helios is the LAN's DNS (Unbound): never MagicDNS
      "--netfilter-mode=off" # Its rules are in ./firewall.nix
    ];
    # The same on every start, also once logged in (tailscale up only runs when logged out)
    extraSetFlags = [
      "--advertise-routes=192.168.0.0/16"
      "--accept-dns=false"
      "--netfilter-mode=off"
    ];
  };
}
