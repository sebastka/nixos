{ lib, ... }:

let
  # The host as containers see it (host.docker.internal), for host services they may reach: only those bound to it.
  # The host's 127.0.0.1 stays closed to containers (rootless Docker's default: --disable-host-loopback), its services
  # unexposed. Link-local, on lo: never routed off the host, and the firewall drops it from the network.
  hostAddress = "169.254.1.2";
in

# Rootless Docker for every user of the desktops: each user's own daemon (a user service), with containers and images
# in ~/.local/share/docker. No root daemon, no docker group. Subordinate UIDs/GIDs: given to normal users
# (autoSubUidGidRange).
# Not started at login: `systemctl --user start docker` when needed (`enable` it to start it at each login).
{
  virtualisation.docker = {
    enable = false; # No system-wide root daemon, no docker group, no root privileges for users

    rootless = {
      enable = true;
      setSocketVariable = true; # DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
      # host.docker.internal: `--add-host=host.docker.internal:host-gateway` (compose: extra_hosts), with the service
      # on the host bound to hostAddress (e.g. `npm run dev -- --host 169.254.1.2`)
      daemon.settings.host-gateway-ips = [ hostAddress ];
    };
  };
  networking.interfaces.lo.ipv4.addresses = [
    {
      address = hostAddress;
      prefixLength = 32;
    }
  ];
  systemd.user.services.docker.wantedBy = lib.mkForce [ ];
}
