{ pkgs, ... }:

# Deep C-states only while the ports are quiet. The I211's (igb) small RX FIFO overflows (rx_missed_errors) while the
# package wakes from deep C-states (C10: 890 us): past C1E, 2-4% of the packets a port receives are lost, and downloads
# cap at ~260-450 Mbit/s, vs 777 Mbit/s without them (./network.nix). On every port: the WAN (downloads), as the LAN
# ports (uploads, backups: there, the WAN only receives their ACKs). Off for the heat, except under load: above 20
# Mbit/s received on any port, a CPU wake-up latency of 20 us at most is asked (PM QoS, held while
# /dev/cpu_dma_latency stays open): C1E (10 us) still, not C3 (70 us) and deeper, as intel_idle.max_cstate=2 did.
# Checked 5 times a second (a burst's first packets come before it is asked), released after 30 quiet seconds.
#   journalctl -u port-latency    Its switches
#   grep . /sys/class/net/enp*/statistics/rx_missed_errors    The losses it is about
let
  portLatency = pkgs.writeShellApplication {
    name = "port-latency";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      threshold_mbits=20
      interval=0.2 # Seconds
      ticks_per_second=5
      quiet_seconds=30
      threshold=$((threshold_mbits * 1000 * 1000 / 8 / ticks_per_second)) # In bytes per interval

      # Every I211 port (igb), found by its driver: enp1s0 (WAN), enp2s0-enp6s0 (LAN)
      ports=()
      for driver in /sys/class/net/*/device/driver; do
        [ "$(basename "$(readlink -f "$driver")")" = igb ] || continue
        port=''${driver%/device/driver}
        ports+=("''${port##*/}")
      done
      echo "Watching ''${ports[*]}"

      declare -A previous
      for port in "''${ports[@]}"; do
        read -r "previous[$port]" < "/sys/class/net/$port/statistics/rx_bytes"
      done

      held=false
      quiet=0
      while sleep "$interval"; do
        busy=""
        for port in "''${ports[@]}"; do
          read -r current < "/sys/class/net/$port/statistics/rx_bytes" # A builtin: no process per port and tick
          rate=$((current - previous[$port]))
          previous[$port]=$current
          if [ "$rate" -gt "$threshold" ] && [ -z "$busy" ]; then
            busy="$port ($((rate * 8 * ticks_per_second / 1000000)) Mbit/s)"
          fi
        done
        if [ -n "$busy" ]; then
          quiet=0
          if ! $held; then
            # 20 us, as the binary s32 the kernel reads: held as long as the file stays open
            exec 3>/dev/cpu_dma_latency
            printf '\x14\x00\x00\x00' >&3
            held=true
            echo "$busy busy: wake-up latency 20 us at most"
          fi
        elif $held; then
          quiet=$((quiet + 1))
          if [ "$quiet" -ge $((quiet_seconds * ticks_per_second)) ]; then
            exec 3>&-
            held=false
            echo "Ports quiet for $quiet_seconds s: deep C-states again"
          fi
        fi
      done
    '';
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
