{ pkgs, ... }:

# Deep C-states only while the ports are quiet. The I211's (igb) small RX FIFO overflows (rx_missed_errors) while the
# package wakes from deep C-states (C10: 890 us): past C1E, 2-4% of the packets a port receives are lost, and downloads
# cap at ~260-450 Mbit/s, vs 777 Mbit/s without them (./network.nix). On every port: the WAN (downloads), as the LAN
# ports (uploads, backups: there, the WAN only receives their ACKs). Off for the heat, except under load: above 20
# Mbit/s received on any port (over a second), a CPU wake-up latency of 20 us at most is asked (PM QoS, held while
# /dev/cpu_dma_latency stays open): C1E (10 us) still, not C3 (70 us) and deeper, as intel_idle.max_cstate=2 did.
# Also within 0.2 s of a burst (a transfer's first packets come before a second's average shows it): above 100
# Mbit/s over 0.2 s. Not 20 Mbit/s there: everyday traffic (a web page, a video's chunk) reaches it in 11% of
# 0.2 s windows, while idle (none above 50 Mbit/s), and would never let it go. Released after 30 seconds, each
# below 20 Mbit/s.
# The script: ./scripts/port-latency.sh
#   journalctl -u port-latency    Its switches
#   grep . /sys/class/net/enp*/statistics/rx_missed_errors    The losses it is about
let
  portLatency = pkgs.writeShellApplication {
    name = "port-latency";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./scripts/port-latency.sh;
  };
in
{
  systemd.services.port-latency = {
    description = "Shallow C-states while a port is busy";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-networkd.service" ]; # Its ports, renamed (enpXs0), found at its start
    serviceConfig = {
      ExecStart = "${portLatency}/bin/port-latency";
      Restart = "always"; # Its request ends with it: deep C-states again, never stuck shallow
    };
  };
}
