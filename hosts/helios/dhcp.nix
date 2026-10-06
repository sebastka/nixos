{ lib, ... }:

# DHCPv4 on the LAN (Kea), from the former Ansible role (templates/etc/kea/kea-dhcp4.conf). DHCPv6 and DDNS stay off.
# Reservations come from ./lan.nix.
let
  lan = import ./lan.nix;
  hook = name: "libdhcp_${name}.so"; # Kea 3: only from its hooks directory (KEA_HOOKS_PATH, set by the module)
  controlSocket = "kea4-ctrl-socket"; # In /run/kea (Kea 3 only allows sockets there)
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

      control-socket = {
        socket-type = "unix";
        socket-name = controlSocket;
      };

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

      renew-timer = 900;
      rebind-timer = 1800;
      valid-lifetime = 3600;

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
          reservations = lib.mapAttrsToList (hostname: host: {
            inherit hostname;
            hw-address = host.mac;
            ip-address = host.ip;
          }) (lib.filterAttrs (_: host: host ? mac) lan.hosts);
        }
      ];

      dhcp-ddns.enable-updates = false;
      ddns-qualifying-suffix = lan.domain;
      ddns-override-client-update = true;
    };
  };

  # Kea's REST API (Stork, scripts), as on Debian: local only
  services.kea.ctrl-agent = {
    enable = true;
    settings = {
      http-host = "127.0.0.1";
      http-port = 8000;
      control-sockets.dhcp4 = {
        socket-type = "unix";
        socket-name = controlSocket;
      };
    };
  };
}
