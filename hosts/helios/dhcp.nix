{ lib, ... }:

# DHCPv4 on the LAN (Kea), from the former Ansible role (templates/etc/kea/kea-dhcp4.conf). DHCPv6 and DDNS stay off.
# Reservations come from ./lan.nix.
let
  lan = import ./lan.nix;
  hook = name: "libdhcp_${name}.so"; # Kea 3: only from its hooks directory (KEA_HOOKS_PATH, set by the module)
in
{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "br0/${lan.router}" ];
        dhcp-socket-type = "raw";
        # br0 may still be coming up: retry instead of failing
        service-sockets-max-retries = 30;
        service-sockets-retry-wait-time = 2000;
      };

      # Kea's API (Stork's agent: ./stork.nix, scripts), local only. Kea 3's own HTTP socket, instead of the control
      # agent (deprecated) in front of a unix socket: one Stork's agent can't use anyway, in /run/kea (Kea's dynamic
      # user only), which it also looks for under Kea's install prefix (the Nix store).
      control-sockets = [
        {
          socket-type = "http";
          socket-address = "127.0.0.1";
          socket-port = 8001;
        }
      ];

      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
        lfc-interval = 3600;
      };

      expired-leases-processing = {
        reclaim-timer-wait-time = 10;
        flush-reclaimed-timer-wait-time = 25;
        hold-reclaimed-time = 3600;
        max-reclaim-leases = 100;
        max-reclaim-time = 250;
        unwarned-reclaim-cycles = 5;
      };

      # Leases of 12 hours, renewed every 15 minutes: clients keep their address through a long outage of helios (a
      # bad update, a failed reboot), the Talos nodes included, which drop theirs when it expires.
      renew-timer = 900;
      rebind-timer = 1800;
      valid-lifetime = 43200;
      # Several reservations may share an IP: a host's network cards (zeus: the same IP on either)
      ip-reservations-unique = false;

      option-data = [
        {
          name = "routers";
          data = lan.router;
        }
        {
          name = "domain-name-servers";
          data = lan.router;
        }
        {
          name = "domain-search";
          data = "${lan.domain}, karlsen.fr";
        }
      ];

      hooks-libraries = [
        { library = hook "bootp"; }
        { library = hook "lease_cmds"; }
        {
          library = hook "perfmon";
          parameters = {
            enable-monitoring = true;
            interval-width-secs = 5;
            stats-mgr-reporting = true;
            alarm-report-secs = 600;
            alarms = [
              {
                duration-key = {
                  query-type = "DHCPDISCOVER";
                  response-type = "DHCPOFFER";
                  start-event = "process-started";
                  stop-event = "process-completed";
                  subnet-id = 0;
                };
                enable-alarm = true;
                high-water-ms = 500;
                low-water-ms = 25;
              }
            ];
          };
        }
        { library = hook "stat_cmds"; }
      ];

      subnet4 = [
        {
          id = 1;
          subnet = "192.168.0.0/16";
          pools = [ { pool = "192.168.0.200 - 192.168.0.249"; } ];
          option-data = [
            {
              name = "routers";
              data = lan.router;
            }
            {
              name = "domain-name-servers";
              data = lan.router;
            }
          ];
          # One per network card (mac, and wakeMacs: zeus's two), with the host's IP
          reservations = lib.concatLists (
            lib.mapAttrsToList (
              hostname: host:
              map (mac: {
                inherit hostname;
                hw-address = mac;
                ip-address = host.ip;
              }) ([ host.mac ] ++ host.wakeMacs or [ ])
            ) (lib.filterAttrs (_: host: host ? mac) lan.hosts)
          );
        }
      ];

      dhcp-ddns.enable-updates = false;
      ddns-qualifying-suffix = lan.domain;
      ddns-override-client-update = true;
    };
  };
}
