#!/usr/bin/env bash
# Shallow C-states while one of helios's ports is busy: why and when, in ../port-latency.nix.
# Packaged with writeShellApplication (../port-latency.nix): it adds its own shebang and strict mode.

interval=0.2 # Seconds
ticks_per_second=5
quiet_seconds=30
second_threshold=$((20 * 1000 * 1000 / 8))                  # 20 Mbit/s over a second, in bytes
burst_threshold=$((100 * 1000 * 1000 / 8 / ticks_per_second)) # 100 Mbit/s over an interval, in bytes

# Every I211 port (igb), found by its driver: enp1s0 (WAN), enp2s0-enp6s0 (LAN)
ports=()
for driver in /sys/class/net/*/device/driver; do
  [ "$(basename "$(readlink -f "$driver")")" = igb ] || continue
  port=${driver%/device/driver}
  ports+=("${port##*/}")
done
echo "Watching ${ports[*]}"

declare -A previous second_start
for port in "${ports[@]}"; do
  read -r "previous[$port]" < "/sys/class/net/$port/statistics/rx_bytes"
  second_start[$port]=${previous[$port]}
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

# Waits with read's timeout, on a pipe nothing writes to: a builtin, where sleep would be a process 5 times a second
# (7% of a core, vs under 1%)
exec 4<> <(:)

held=false
quiet=0 # Quiet seconds in a row
tick=0
while true; do
  read -r -t "$interval" -u 4 || true
  tick=$((tick + 1))
  for port in "${ports[@]}"; do
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
  for port in "${ports[@]}"; do
    second=$((previous[$port] - second_start[$port]))
    second_start[$port]=${previous[$port]}
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
