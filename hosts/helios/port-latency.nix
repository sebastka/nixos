{ pkgs, ... }:

# Deep C-states only while the ports are quiet. The I211's (igb) small RX FIFO overflows (rx_missed_errors) while the
# package wakes from deep C-states (C10: 890 us): past C1E, 2-4% of the packets a port receives are lost, and downloads
# cap at ~260-450 Mbit/s, vs 777 Mbit/s without them (./network.nix). On every port: the WAN (downloads), as the LAN
# ports (uploads, backups: there, the WAN only receives their ACKs). Off for the heat, except under load: above 20
# Mbit/s received on any port (over a second), a CPU wake-up latency of 20 us at most is asked (PM QoS, held while
# /dev/cpu_dma_latency stays open): C1E (10 us) still, not C3 (70 us) and deeper, as intel_idle.max_cstate=2 did.
# Also within a check of a burst (a transfer's first packets come before a second's average shows it; every 0.1 s
# for the C version, 0.2 s for the shell script): above 100 Mbit/s over it. Not 20 Mbit/s there: everyday traffic (a
# web page, a video's chunk) reaches it in 11% of 0.2 s windows, while idle (none above 50 Mbit/s, nor above 100 over
# 0.1 s), and would never let it go. Released after 30 seconds, each below 20 Mbit/s.
# The program: ./src/port-latency.c (or the shell script, ./scripts/port-latency.sh, below)
#   journalctl -u port-latency    Its switches
#   grep . /sys/class/net/enp*/statistics/rx_missed_errors    The losses it is about
let
  # Testing: ./src/port-latency.c, every 0.1 s (0.7% of a core, vs 2.1% for the shell script at 0.1 s, 1.1% at 0.2 s)
  portLatency = pkgs.runCommandCC "port-latency" { meta.mainProgram = "port-latency"; } ''
    mkdir -p $out/bin
    $CC -O2 -Wall -Wextra -Werror -o $out/bin/port-latency ${./src/port-latency.c}
  '';
  # The shell script, every 0.2 s, until the test convinces
  # portLatency = pkgs.writeShellApplication {
  #   name = "port-latency";
  #   runtimeInputs = [ pkgs.coreutils ];
  #   text = builtins.readFile ./scripts/port-latency.sh;
  # };
in
{
  systemd.services.port-latency = {
    description = "Shallow C-states while a port is busy";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-networkd.service" ]; # Its ports, renamed (enpXs0), found at its start
    serviceConfig = {
      # Testing -b 20: C1E (10 us) at most, all the time, as intel_idle.max_cstate=2 did: do C-states cause helios's
      # losses at all? -b 150 (at most C7s) didn't reduce them (2026-10-20/21: 0.27% on enp1s0, 1.07% on enp6s0), and
      # its I211s have no ASPM (the cause on the I226-V machines). If they stop: the limit is between 20 and 150 us
      # (next: -b 75, C3). If not: not the CPU's sleep (next: the I211's DMA coalescing, flow control, the switch's
      # bursts). Compare rx_missed_errors per received packet, and x86_pkg_temp (48 °C quiet without a base, 60 °C
      # with -b 150).
      ExecStart = "${portLatency}/bin/port-latency -i 100 -b 20";
      Restart = "always"; # Its request ends with it: deep C-states again, never stuck shallow
    };
  };
}
