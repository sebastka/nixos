{
  config,
  lib,
  pkgs,
  ...
}:

# Off-site backups of the data disk's shares (./nfs.nix), not homelab: Kopia, nightly, one job (a snapshot source) per
# share, into one encrypted repository in the Hetzner bucket sebastka-homelab-files (sebastka/homelab:
# tofu-hetzner/buckets.tf). The bucket locks every object version for 30 days, COMPLIANCE: no one can delete or
# overwrite them before then, not even with the S3 key this host holds. Kopia locks what it writes the same way, and
# renews the locks of what it still uses at each full maintenance (--extend-object-locks), so current data stays
# locked for as long as it is kept.
#
# Credentials: kopia-env in secrets/file.sops.yaml, an environment file (sops edit secrets/file.sops.yaml):
#   KOPIA_PASSWORD=...           The repository's encryption password: without it, the backups are unreadable
#   AWS_ACCESS_KEY_ID=...        An S3 key pair of the Hetzner project (Cloud Console: Security > S3 credentials)
#   AWS_SECRET_ACCESS_KEY=...
# Keep the password somewhere else too (Bitwarden): it is the only way back into the repository.
#
# Once, as root (`sudo kopia`: the wrapper below, with the credentials and the repository's config):
#   sudo kopia repository create s3 --bucket=sebastka-homelab-files --endpoint=hel1.your-objectstorage.com \
#     --region=hel1 --retention-mode=COMPLIANCE --retention-period=30d
#   sudo kopia maintenance set --extend-object-locks=true    # Its full interval (24 h) must stay under 29 days
# Snapshot retention: Kopia's default global policy (the latest 10, 48 hourly, 7 daily, 4 weekly, 24 monthly, 3
# annual), `sudo kopia policy show --global`. What it drops stays in the bucket until its lock runs out.
#
#   systemctl list-timers 'kopia-*'                 The schedule
#   journalctl -u 'kopia-snapshot@*'                 The last runs
#   sudo kopia snapshot list --all                   The snapshots
#   sudo kopia mount all /mnt/restore                Browse them (or `kopia snapshot restore <id> <dir>`)
let
  data = "/mnt/data_disk1";
  shares = [
    "Documents"
    "Downloads"
    "Music"
    "Pictures"
    "Torrent"
    "Videos"
  ];

  stateDir = "/var/lib/kopia";
  environment = {
    KOPIA_CONFIG_PATH = "${stateDir}/repository.config"; # Written by `kopia repository create` (or connect)
    KOPIA_CACHE_DIRECTORY = "/var/cache/kopia";
    KOPIA_LOG_DIR = "/var/log/kopia";
    KOPIA_CHECK_FOR_UPDATES = "false";
  };

  # kopia as root with the repository's credentials: the jobs' and the admin's (sudo kopia ...) command
  kopia = pkgs.writeShellApplication {
    name = "kopia";
    runtimeInputs = [ pkgs.kopia ];
    text = ''
      if [ ! -r ${config.sops.secrets.kopia-env.path} ]; then
        echo "kopia: the repository's credentials are root's: sudo kopia $*" >&2
        exit 1
      fi
      set -a
      # shellcheck disable=SC1091 # The credentials, at runtime (sops-nix)
      . ${config.sops.secrets.kopia-env.path}
      set +a
      ${lib.concatStrings (
        lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}\n") environment
      )}
      exec kopia "$@"
    '';
  };

  serviceConfig = {
    # Started once Kopia runs, not once it's done (oneshot): `systemctl start` returns at once, instead of for the
    # backup's whole length. Failures still show in `systemctl status` and the journal.
    Type = "exec";
    StateDirectory = "kopia";
    StateDirectoryMode = "0700";
    CacheDirectory = "kopia";
    LogsDirectory = "kopia";
    Nice = 10;
    IOSchedulingClass = "idle"; # NFS clients first
  };
in
{
  sops.secrets.kopia-env.sopsFile = ../../secrets/file.sops.yaml;

  environment.systemPackages = [ kopia ];

  # One job per share: kopia-snapshot@Documents.service...
  systemd.services."kopia-snapshot@" = {
    description = "Kopia snapshot of ${data}/%i";
    # A deploy leaves a running backup alone (a changed unit would be restarted, which waited for hours): the new
    # definition applies from the next run
    restartIfChanged = false;
    # Only with the data disk mounted: a snapshot of its empty mount point would look like everything deleted
    unitConfig = {
      RequiresMountsFor = data;
      ConditionPathIsMountPoint = data;
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = serviceConfig // {
      # 8 files at once: by default Kopia goes by the CPUs (2 here), which left a single upload to Hetzner, about
      # 40 Mbit/s for one TCP stream (21 ms away, its window shrunk by losses). Several streams fill the uplink.
      ExecStart = "${lib.getExe kopia} snapshot create --parallel=8 ${data}/%i";
    };
  };

  # Nightly, before the reboot window of the automatic upgrades (04:00-06:00, modules/nixos/server)
  systemd.timers =
    lib.listToAttrs (
      map (
        share:
        lib.nameValuePair "kopia-snapshot@${share}" {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "01:00";
            RandomizedDelaySec = "30min"; # Not all six at once
            Persistent = true; # Missed (the VM was down): at the next start
          };
        }
      ) shares
    )
    // {
      # Full maintenance: drops what no snapshot needs any more, and renews the locks of the rest (its interval must
      # stay under the 30-day lock). Kopia skips it when it isn't due yet.
      kopia-maintenance = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "03:00";
          Persistent = true;
        };
      };
    };

  systemd.services.kopia-maintenance = {
    description = "Kopia full maintenance (renews the object locks)";
    restartIfChanged = false; # As the snapshots'
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = serviceConfig // {
      ExecStart = "${lib.getExe kopia} maintenance run --full";
    };
  };
}
