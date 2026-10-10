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
  # hostAddress on its own interface, from NetworkManager (networking.interfaces.lo is never applied: nothing starts
  # its service)
  networking.networkmanager.ensureProfiles.profiles.docker-host = {
    connection = {
      id = "docker-host";
      uuid = "c8f8e215-7b99-4598-9f0e-893f760d790e";
      type = "dummy";
      interface-name = "docker-host";
    };
    ipv4 = {
      method = "manual";
      address1 = "${hostAddress}/32";
      never-default = true;
    };
    ipv6.method = "disabled";
  };
  systemd.user.services.docker.wantedBy = lib.mkForce [ ];
}
