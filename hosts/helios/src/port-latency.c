// Shallow C-states while one of helios's ports is busy: why and when, in ../port-latency.nix. The same rules as
// ../scripts/port-latency.sh, in C: each counter file opened once (pread at offset 0 rereads it), an absolute clock
// (no drift), no process per check.
//
// Usage: port-latency [-i interval_ms] [-q quiet_seconds] [-b base_us] [-d device]
//   -i  Check interval, in ms (default 100; 1000 must be a multiple of it)
//   -q  Quiet seconds before releasing (default 30)
//   -b  A base wake-up latency, in us, asked for all the time (default none): the C-states too slow for the RX FIFO
//       forbidden even while quiet, for the bursts shorter than a check. The kernel applies the lowest request: 20 us
//       while busy all the same.
//   -d  The PM QoS device (default /dev/cpu_dma_latency; another file, to test without root)

#define _GNU_SOURCE
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <libgen.h>
#include <limits.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define MAX_PORTS 16
#define SECOND_MBITS 20  // Over a second
#define BURST_MBITS 100  // Over an interval
#define LATENCY_US 20    // C1E (10 us) still, not C3 (70 us) and deeper

// IFNAMSIZ is 16 (net/if.h), without pulling its definitions in
enum { IFNAMSIZ_MAX = 16 };

struct port {
  char name[IFNAMSIZ_MAX];
  int fd;                 // Its rx_bytes, kept open
  uint64_t previous;      // At the last check
  uint64_t second_start;  // At the start of the current second
};

static uint64_t read_counter(int fd) {
  char buf[32];
  ssize_t n = pread(fd, buf, sizeof buf - 1, 0);
  if (n <= 0) {
    perror("pread rx_bytes");
    exit(1);
  }
  buf[n] = '\0';
  return strtoull(buf, NULL, 10);
}

// Every I211 port (igb), found by its driver: enp1s0 (WAN), enp2s0-enp6s0 (LAN)
static int find_ports(struct port *ports) {
  DIR *dir = opendir("/sys/class/net");
  if (!dir) {
    perror("/sys/class/net");
    exit(1);
  }
  int count = 0;
  struct dirent *entry;
  while ((entry = readdir(dir)) && count < MAX_PORTS) {
    size_t length = strlen(entry->d_name);
    if (entry->d_name[0] == '.' || length >= IFNAMSIZ_MAX) continue;  // Interface names: 15 characters at most
    char path[PATH_MAX], target[PATH_MAX];
    snprintf(path, sizeof path, "/sys/class/net/%s/device/driver", entry->d_name);
    ssize_t n = readlink(path, target, sizeof target - 1);
    if (n < 0) continue;  // Virtual: br0, lo...
    target[n] = '\0';
    if (strcmp(basename(target), "igb") != 0) continue;

    struct port *port = &ports[count];
    memcpy(port->name, entry->d_name, length + 1);
    snprintf(path, sizeof path, "/sys/class/net/%s/statistics/rx_bytes", entry->d_name);
    port->fd = open(path, O_RDONLY | O_CLOEXEC);
    if (port->fd < 0) {
      perror(path);
      exit(1);
    }
    port->previous = port->second_start = read_counter(port->fd);
    count++;
  }
  closedir(dir);
  return count;
}

static const char *device = "/dev/cpu_dma_latency";
static int held_fd = -1;  // Open while held: the kernel keeps the request as long as the file stays open
static int quiet;         // Quiet seconds in a row

// A PM QoS request, kept as long as the returned file stays open
static int request(int32_t latency_us) {
  int fd = open(device, O_WRONLY | O_CLOEXEC | O_CREAT, 0600);  // O_CREAT: only for a test file (-d)
  // As the binary s32 the kernel reads
  if (fd < 0 || write(fd, &latency_us, sizeof latency_us) != sizeof latency_us) {
    perror(device);
    exit(1);
  }
  return fd;
}

static void hold(const char *port, uint64_t bytes, double seconds) {
  quiet = 0;
  if (held_fd >= 0) return;
  held_fd = request(LATENCY_US);
  printf("%s (%" PRIu64 " Mbit/s over %g s) busy: wake-up latency %d us at most\n", port,
         (uint64_t)(bytes * 8 / seconds / 1000000), seconds, LATENCY_US);
}

static void release(int quiet_seconds) {
  close(held_fd);
  held_fd = -1;
  printf("Ports quiet for %d s: deep C-states again\n", quiet_seconds);
}

int main(int argc, char **argv) {
  int interval_ms = 100, quiet_seconds = 30, base_us = 0, opt;
  while ((opt = getopt(argc, argv, "i:q:b:d:")) != -1) {
    switch (opt) {
      case 'i': interval_ms = atoi(optarg); break;
      case 'q': quiet_seconds = atoi(optarg); break;
      case 'b': base_us = atoi(optarg); break;
      case 'd': device = optarg; break;
      default:
        fprintf(stderr, "Usage: %s [-i interval_ms] [-q quiet_seconds] [-b base_us] [-d device]\n", argv[0]);
        return 2;
    }
  }
  if (interval_ms <= 0 || 1000 % interval_ms != 0 || quiet_seconds <= 0 || base_us < 0 ||
      (base_us > 0 && base_us <= LATENCY_US)) {
    fprintf(stderr, "%s: the interval must divide 1000 ms, the quiet time be positive, the base above %d us\n",
            argv[0], LATENCY_US);
    return 2;
  }
  setvbuf(stdout, NULL, _IOLBF, 0);  // A line at a time to the journal

  if (base_us > 0) {
    request(base_us);  // Never closed: for as long as the program runs
    printf("Base wake-up latency: %d us at most, all the time\n", base_us);
  }

  struct port ports[MAX_PORTS];
  int count = find_ports(ports);
  if (count == 0) {
    fprintf(stderr, "%s: no igb port\n", argv[0]);
    return 1;
  }
  printf("Watching");
  for (int i = 0; i < count; i++) printf(" %s", ports[i].name);
  printf(", every %d ms\n", interval_ms);

  const int ticks_per_second = 1000 / interval_ms;
  const uint64_t second_threshold = (uint64_t)SECOND_MBITS * 1000000 / 8;
  const uint64_t burst_threshold = (uint64_t)BURST_MBITS * 1000000 / 8 / ticks_per_second;
  const double interval = interval_ms / 1000.0;

  struct timespec next;
  clock_gettime(CLOCK_MONOTONIC, &next);
  for (long tick = 1;; tick++) {
    next.tv_nsec += (long)interval_ms * 1000000;
    if (next.tv_nsec >= 1000000000) {
      next.tv_sec++;
      next.tv_nsec -= 1000000000;
    }
    while (clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next, NULL) == EINTR) {
    }

    for (int i = 0; i < count; i++) {
      uint64_t current = read_counter(ports[i].fd);
      uint64_t burst = current - ports[i].previous;
      ports[i].previous = current;
      if (burst > burst_threshold) hold(ports[i].name, burst, interval);
    }

    if (tick % ticks_per_second != 0) continue;
    // Each second: its average, per port
    bool busy_second = false;
    for (int i = 0; i < count; i++) {
      uint64_t second = ports[i].previous - ports[i].second_start;
      ports[i].second_start = ports[i].previous;
      if (second > second_threshold) {
        busy_second = true;
        hold(ports[i].name, second, 1);
      }
    }
    if (held_fd >= 0 && !busy_second && ++quiet >= quiet_seconds) release(quiet_seconds);
  }
}
