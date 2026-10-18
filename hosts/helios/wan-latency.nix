{ pkgs, ... }:

# Deep C-states only while the WAN is quiet. The I211's (igb) small RX FIFO overflows (rx_missed_errors) while the
# package wakes from deep C-states (C10: 890 us): past C1E, 2-4% of WAN packets are lost and downloads cap at ~260-450
# Mbit/s, vs 777 Mbit/s without them (./network.nix). Off for the heat, except under load: above 20 Mbit/s received on
# the WAN, a CPU wake-up latency of 20 us at most is asked (PM QoS, held while /dev/cpu_dma_latency stays open): C1E
# (10 us) still, not C3 (70 us) and deeper, as intel_idle.max_cstate=2 did. Released after 30 quiet seconds.
#   journalctl -u wan-latency    Its switches
#   cat /sys/class/net/enp1s0/statistics/rx_missed_errors    The losses it is about
let
  wanLatency = pkgs.writeShellApplication {
    name = "wan-latency";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      interface=enp1s0
      threshold=$((20 * 1000 * 1000 / 8)) # 20 Mbit/s, in bytes per second
      quiet_seconds=30
      counter=/sys/class/net/$interface/statistics/rx_bytes

      held=false
      quiet=0
      previous=$(cat "$counter")
      while sleep 1; do
        current=$(cat "$counter")
        rate=$((current - previous))
        previous=$current
        if [ "$rate" -gt "$threshold" ]; then
          quiet=0
          if ! $held; then
            # 20 us, as the binary s32 the kernel reads: held as long as the file stays open
            exec 3>/dev/cpu_dma_latency
            printf '\x14\x00\x00\x00' >&3
            held=true
            echo "$interface busy ($((rate * 8 / 1000000)) Mbit/s): wake-up latency 20 us at most"
          fi
        elif $held; then
          quiet=$((quiet + 1))
          if [ "$quiet" -ge "$quiet_seconds" ]; then
            exec 3>&-
            held=false
            echo "$interface quiet for $quiet_seconds s: deep C-states again"
          fi
        fi
      done
    '';
  };
in
{
  systemd.services.wan-latency = {
    description = "Shallow C-states while the WAN is busy";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${wanLatency}/bin/wan-latency";
      Restart = "always"; # Its request ends with it: deep C-states again, never stuck shallow
    };
  };
}
