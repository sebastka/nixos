{ ... }:

# The router in the cluster's monitoring (homelab repo: k8s/infrastructure/monitoring), as the cluster's own nodes:
# - Metrics, scraped by VictoriaMetrics' vmagent (victoria-metrics-k8s-stack, VMStaticScrape.helios.yaml), from the
#   cluster's nodes (./firewall.nix): the node exporter's (CPU, temperatures, network, conntrack...) on :9100, and
#   Kea's statistics on :9547, exported by the Stork agent (./stork.nix).
# - Logs: the journal, pushed to VictoriaLogs (its journald endpoint, through the cluster's internal gateway).
let
  lan = import ./lan.nix;
in
{
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = lan.router; # The LAN only
    port = 9100;
    enabledCollectors = [ "systemd" ]; # Units' states, besides the defaults (hwmon, netdev, conntrack...)
  };
  # Once br0 has its address (network-online.target waits for it, ./network.nix): earlier, it can't bind to it ("cannot
  # assign requested address") and gives up after 5 quick restarts. Slower restarts all the same.
  systemd.services.prometheus-node-exporter = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig.RestartSec = "5s";
  };

  services.journald.upload = {
    enable = true;
    settings.Upload = {
      # The port explicitly: without one, journal-upload appends its own (:19532) to the end of the URL, path included
      # (".../insert/journald:19532/upload"). /upload is appended to the path.
      URL = "https://victorialogs.talmox.hera.home.karlsen.fr:443/insert/journald";
      # No client certificate (VictoriaLogs asks none), and the server's (Let's Encrypt) checked against the system's
      # CAs: by default, journal-upload looks for its own in /etc/ssl (private/journal-upload.pem, ca/trusted.pem)
      ServerKeyFile = "-";
      ServerCertificateFile = "-";
      TrustedCertificateFile = "/etc/ssl/certs/ca-certificates.crt";
    };
  };
}
