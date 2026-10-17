{
  config,
  lib,
  ...
}:

# Syncthing on desktops, through the homelab's Syncthing server (homelab repo, k8s/applications/utils/syncthing), for
# the user who enables it on the desktops (services.syncthing: enable, user, group, dataDir, and settings.folders, in
# users/<user>/desktop.nix). Each desktop works on its local copy: a save is a local write, and Syncthing sends the
# change in the background a few seconds later.
#
# Hub and spokes: desktops share their folders only with the server, as an untrusted device. It stores them encrypted
# (with the password from desktop.sops.yaml), and passes them on to the other desktops, which decrypt them with the
# same password. Every folder gets that by default (below): a user only lists theirs.
let
  cfg = config.services.syncthing;

  # The server's device ID (Actions > Show ID in its web UI, syncthing.talmox.hera.home.karlsen.fr). The server knows
  # each desktop by the device ID of its key (syncthing-cert and syncthing-key in the host's own sops file), declared
  # in its config.xml (homelab repo): it shares the folders with them in advance.
  serverDeviceId = "7Y3CMXX-T3O65K6-UGOSYV7-74N543F-2TIGEI5-HI7EGJM-UHYVNF4-7NE7DAP";
  server = "talmox";

  # Rebuildable or machine-local: not synced. **/ matches at any depth; (?d) lets Syncthing delete them when they
  # block a directory removal. Add more as needed: it applies to every folder.
  ignorePatterns = [
    "(?d).DS_Store"
    "(?d)Thumbs.db"
    "**/node_modules"
    "**/.venv"
    "**/venv"
    "**/__pycache__"
    "**/.direnv"
    "**/result"
    "**/result-*"
    "**/target"
    "**/.cache"
    "**/base/charts" # kustomize helmCharts caches (not YAML/charts, the chart sources)
    "**/overlays/*/charts"
    "**/.terraform"
  ];
in
{
  # Every folder's defaults: shared with the server only, encrypted there; ignore patterns, watcher and versioning
  options.services.syncthing.settings.folders = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        config = {
          devices = lib.mkDefault [
            {
              name = server;
              encryptionPasswordFile = config.sops.secrets."syncthing-encryption-password".path;
            }
          ];
          ignorePatterns = lib.mkDefault ignorePatterns;
          # A few seconds after the last change (default 10s): saves never wait on it
          fsWatcherEnabled = lib.mkDefault true;
          versioning = lib.mkDefault {
            type = "trashcan";
            params.cleanoutDays = "7";
          };
        };
      }
    );
  };

  config = lib.mkIf cfg.enable {
    # Desktop-only secret (not readable by servers): the password the server's copies are encrypted with
    sops.secrets."syncthing-encryption-password" = {
      sopsFile = ../../../secrets/desktop.sops.yaml;
      owner = cfg.user;
    };

    # This desktop's identity (its device ID), fixed so the server can know it in advance. Readable by this host alone;
    # the service copies them into its configDir as root.
    sops.secrets."syncthing-cert".sopsFile =
      ../../../secrets + "/${config.networking.hostName}.sops.yaml";
    sops.secrets."syncthing-key".sopsFile =
      ../../../secrets + "/${config.networking.hostName}.sops.yaml";

    # One watch per directory: a folder like ~/Dev alone has tens of thousands
    boot.kernel.sysctl."fs.inotify.max_user_watches" = 1048576;

    services.syncthing = {
      cert = config.sops.secrets."syncthing-cert".path;
      key = config.sops.secrets."syncthing-key".path;
      openDefaultPorts = false; # Desktops connect out to the server only
      overrideDevices = true;
      overrideFolders = true;

      settings = {
        options = {
          # The server is known by address: no discovery servers, relays or UPnP
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          urAccepted = -1; # No usage reporting
        };

        devices.${server} = {
          id = serverDeviceId;
          # At home, helios answers with its LoadBalancer (192.168.2.14); elsewhere, public DNS gives the public IP,
          # which helios forwards to it (TCP and UDP 22000)
          addresses = [
            "tcp://sync.karlsen.fr:22000"
            "quic://sync.karlsen.fr:22000"
          ];
        };
      };
    };
  };
}
