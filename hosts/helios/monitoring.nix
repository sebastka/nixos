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

  services.journald.upload = {
    enable = true;
    settings.Upload = {
      URL = "https://victorialogs.talmox.hera.home.karlsen.fr/insert/journald"; # /upload appended by journal-upload
      # No client certificate (VictoriaLogs asks none), and the server's (Let's Encrypt) checked against the system's
      # CAs: by default, journal-upload looks for its own in /etc/ssl (private/journal-upload.pem, ca/trusted.pem)
      ServerKeyFile = "-";
      ServerCertificateFile = "-";
      TrustedCertificateFile = "/etc/ssl/certs/ca-certificates.crt";
    };
  };
}
