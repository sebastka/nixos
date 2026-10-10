{ lib, ... }:

let
  # The host as containers see it (host.docker.internal), for host services they may reach: only those bound to it.
  # The host's 127.0.0.1 stays closed to containers (rootless Docker's default: --disable-host-loopback), its services
  # unexposed. Link-local: never routed off the host, and the firewall drops it from the network.
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
  # For scripts and compose files: `--host ${CONTAINER_HOST_ADDRESS:-127.0.0.1}` (the fallback where it's unset)
  environment.sessionVariables.CONTAINER_HOST_ADDRESS = hostAddress;
  # hostAddress on lo, from NetworkManager: a loopback profile, which keeps 127.0.0.1 and ::1 and isn't listed in
  # Plasma's network applet (networking.interfaces.lo is never applied: nothing starts its service). Not named "lo":
  # NetworkManager's own lo.nmconnection, for lo without a profile, is in the same directory.
  networking.networkmanager.ensureProfiles.profiles.loopback = {
    connection = {
      id = "loopback";
      uuid = "9b6a46d8-0fff-4b28-b750-1822b5d5fe00";
      type = "loopback";
      interface-name = "lo";
    };
    ipv4 = {
      method = "manual";
      address1 = "${hostAddress}/32";
    };
  };
  systemd.user.services.docker.wantedBy = lib.mkForce [ ];
}
