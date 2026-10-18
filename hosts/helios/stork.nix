{ pkgs, ... }:

# ISC Stork's agent: Kea's DHCP for the Stork server in the cluster (stork.talmox.hera.home.karlsen.fr, homelab repo:
# k8s/infrastructure/monitoring/stork). Not on Debian's helios. The agent finds Kea through its processes (hence
# CAP_SYS_PTRACE) and their configuration: Kea's HTTP control socket, on 127.0.0.1:8001 (./dhcp.nix).
#
# Registration, once: the agent registers with the server at its first start (its certificates then kept in
# /var/lib/stork-agent). Approve it in Stork's web interface: Services > Machines > Unauthorized, helios.
let
  lan = import ./lan.nix;
  stork-agent = pkgs.callPackage ../../pkgs/isc-stork-agent { };
in
{
  environment.systemPackages = [ stork-agent ]; # stork-agent register..., man stork-agent

  systemd.services.stork-agent = {
    description = "ISC Stork Agent";
    documentation = [ "man:stork-agent(8)" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "kea-dhcp4-server.service"
    ];
    environment = {
      # For the Stork server (from the cluster's nodes: ./firewall.nix)
      STORK_AGENT_HOST = lan.router;
      STORK_AGENT_PORT = "8080";
      # And Kea's statistics for VictoriaMetrics (./monitoring.nix)
      STORK_AGENT_PROMETHEUS_KEA_EXPORTER_ADDRESS = lan.router;
      STORK_AGENT_PROMETHEUS_KEA_EXPORTER_PORT = "9547";
      STORK_AGENT_SERVER_URL = "https://stork.talmox.hera.home.karlsen.fr";
      CLICOLOR = "false";
    };
    serviceConfig = {
      ExecStart = "${stork-agent}/bin/stork-agent";
      ExecReload = "kill -HUP $MAINPID";
      Restart = "on-failure";
      DynamicUser = true;
      StateDirectory = "stork-agent"; # /var/lib/stork-agent: its certificates
      WorkingDirectory = "/var/lib/stork-agent";
      AmbientCapabilities = [ "CAP_SYS_PTRACE" ]; # To read Kea's processes
      CapabilityBoundingSet = [ "CAP_SYS_PTRACE" ];
    };
  };
}
