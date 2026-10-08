{ lib, ... }:

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
    };
  };
  systemd.user.services.docker.wantedBy = lib.mkForce [ ];
}
