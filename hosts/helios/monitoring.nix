{ ... }:

# The router in the cluster's monitoring (homelab repo: k8s/infrastructure/monitoring), as the cluster's own nodes:
# - Metrics, scraped by VictoriaMetrics' vmagent (victoria-metrics-k8s-stack, VMStaticScrape.helios.yaml), from the
#   cluster's nodes (./firewall.nix): the node exporter's (CPU, temperatures, network, conntrack...) on :9100, and
#   Kea's statistics on :9547, exported by the Stork agent (./stork.nix).
# - Logs: the journal, pushed to VictoriaLogs by Vector (through the cluster's internal gateway).
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

  # The journal to VictoriaLogs, by Vector: its Elasticsearch bulk API, as VictoriaLogs documents for Vector. Not
  # systemd-journal-upload: over HTTP/2 (the gateway's choice), libcurl hands it buffers too small for an entry ("Buffer
  # space is too small to write entry"), retried forever on the same one, and it can't be told to use HTTP/1.1.
  # Its position in the journal is kept in /var/lib/vector: a restart resumes there.
  services.vector = {
    enable = true;
    journaldAccess = true; # The systemd-journal group
    settings = {
      data_dir = "/var/lib/vector";
      sources.journald.type = "journald";
      sinks.victorialogs = {
        type = "elasticsearch";
        inputs = [ "journald" ];
        endpoints = [ "https://victorialogs.talmox.hera.home.karlsen.fr/insert/elasticsearch/" ];
        mode = "bulk";
        api_version = "v8";
        compression = "gzip";
        healthcheck.enabled = false;
        # VictoriaLogs' fields: the message, its time, and the streams (by host and unit)
        query = {
          _msg_field = "message";
          _time_field = "timestamp";
          _stream_fields = "host,_SYSTEMD_UNIT";
        };
      };
    };
  };
  systemd.services.vector = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
