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
#   journalctl -u port-latency    Its switches
#   grep . /sys/class/net/enp*/statistics/rx_missed_errors    The losses it is about
let
  portLatency = pkgs.writeShellApplication {
    name = "port-latency";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      interval=0.2 # Seconds
      ticks_per_second=5
      quiet_seconds=30
      second_threshold=$((20 * 1000 * 1000 / 8))                  # 20 Mbit/s over a second, in bytes
      burst_threshold=$((100 * 1000 * 1000 / 8 / ticks_per_second)) # 100 Mbit/s over an interval, in bytes

      # Every I211 port (igb), found by its driver: enp1s0 (WAN), enp2s0-enp6s0 (LAN)
      ports=()
      for driver in /sys/class/net/*/device/driver; do
        [ "$(basename "$(readlink -f "$driver")")" = igb ] || continue
        port=''${driver%/device/driver}
        ports+=("''${port##*/}")
      done
      echo "Watching ''${ports[*]}"

      declare -A previous second_start
      for port in "''${ports[@]}"; do
        read -r "previous[$port]" < "/sys/class/net/$port/statistics/rx_bytes"
        second_start[$port]=''${previous[$port]}
      done

      hold() { # Why
        quiet=0
        $held && return
        # 20 us, as the binary s32 the kernel reads: held as long as the file stays open
        exec 3>/dev/cpu_dma_latency
        printf '\x14\x00\x00\x00' >&3
        held=true
        echo "$1 busy: wake-up latency 20 us at most"
      }

      held=false
      quiet=0 # Quiet seconds in a row
      tick=0
      while sleep "$interval"; do
        tick=$((tick + 1))
        for port in "''${ports[@]}"; do
          read -r current < "/sys/class/net/$port/statistics/rx_bytes" # A builtin: no process per port and tick
          burst=$((current - previous[$port]))
          previous[$port]=$current
          if [ "$burst" -gt "$burst_threshold" ]; then
            hold "$port ($((burst * 8 * ticks_per_second / 1000000)) Mbit/s over $interval s)"
          fi
        done

        [ $((tick % ticks_per_second)) -eq 0 ] || continue
        # Each second: its average, per port
        busy_second=false
        for port in "''${ports[@]}"; do
          second=$((previous[$port] - second_start[$port]))
          second_start[$port]=''${previous[$port]}
          if [ "$second" -gt "$second_threshold" ]; then
            busy_second=true
            hold "$port ($((second * 8 / 1000000)) Mbit/s over 1 s)"
          fi
        done
        if $held && ! $busy_second; then
          quiet=$((quiet + 1))
          if [ "$quiet" -ge "$quiet_seconds" ]; then
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
