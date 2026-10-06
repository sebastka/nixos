# Work (inboxcom): sebastian's work setup, on desktops only. NixOS module, as it declares secrets: desktops must be
# recipients of secrets/ssh-work.sops.yaml and secrets/desktop.sops.yaml (.sops.yaml).
{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  user = "sebastian";
  nixosConfig = config;
  bitwarden-cli = pkgs.callPackage ../../pkgs/bitwarden-cli { };

  bitwarden = account: profile: {
    name = "Bitwarden (${account})";
    url = "https://vault.bitwarden.eu/#/vault";
    inherit profile;
    icon = ./icons/bitwarden.svg;
    genericName = "Password Manager";
    comment = "Bitwarden web vault for ${account}";
  };
in
{
  config = lib.mkIf nixosConfig.services.xserver.enable {
    sops.secrets = {
      # Work SSH hosts and their keys (company infrastructure: encrypted), linked under ~/.ssh
      ssh-work-config = {
        sopsFile = "${self}/secrets/ssh-work.sops.yaml";
        owner = user;
      };
      ssh-work-known-hosts = {
        sopsFile = "${self}/secrets/ssh-work.sops.yaml";
        owner = user;
      };
      # Bitwarden Secrets Manager config, linked under ~/.config
      bws-inboxcom-config = {
        sopsFile = "${self}/secrets/desktop.sops.yaml";
        owner = user;
      };
    };

    home-manager.users.${user} =
      { config, lib, ... }: # home-manager's (lib.hm)
      {
        # Work repositories: inboxcom identity, signing key and SSH key for GitHub
        # (same host as personal repos, GitHub picks the account from the SSH key).
        programs.git.includes = [
          {
            condition = "gitdir:~/Dev/Work/";
            contents = {
              user.email = "sebastian@corp.inbox.com";
              user.signingKey = "6908E0776A37F2BAAC4E192FE361F48DB812586F";
              core.sshCommand = "ssh -i ~/.ssh/key/inboxcom.id_ed25519_gpg.pub";
            };
          }
        ];

        # Work SSH key: the inboxcom Yubikey's OpenPGP authentication subkey (as the personal one, ./home.nix),
        # for the work servers (and GitHub's work account, programs.git.includes above)
        home.file.".ssh/key/inboxcom.id_ed25519_gpg.pub".source = ./keys/inboxcom.id_ed25519_gpg.pub;
        programs.ssh.settings."*.fjordmail.no".IdentityFile = "~/.ssh/key/inboxcom.id_ed25519_gpg.pub";

        # Work SSH hosts and their keys (secrets above), next to the personal ones (./home.nix)
        home.file.".ssh/config.d/work.conf".source =
          config.lib.file.mkOutOfStoreSymlink nixosConfig.sops.secrets.ssh-work-config.path;
        home.file.".ssh/known_hosts.d/inboxcom".source =
          config.lib.file.mkOutOfStoreSymlink nixosConfig.sops.secrets.ssh-work-known-hosts.path;

        # Bitwarden Secrets Manager (bws): inboxcom account only, selected with BWS_CONFIG_FILE (see README.md).
        xdg.configFile."bws/inboxcom.config".source =
          config.lib.file.mkOutOfStoreSymlink nixosConfig.sops.secrets.bws-inboxcom-config.path;

        # Bitwarden CLI (bw): the inboxcom account's data directory (the private one is the default, ./desktop.nix).
        # bw keeps its server URL in its data file (with the login session), which it rewrites itself:
        # set the server once, only when the data directory doesn't exist yet.
        home.activation.bitwardenCliInboxcom = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          dir="${config.xdg.dataHome}/bitwarden-cli/inboxcom"
          if [ ! -e "$dir/data.json" ]; then
            BITWARDENCLI_APPDATA_DIR="$dir" run ${lib.getExe bitwarden-cli} config server https://vault.bitwarden.eu > /dev/null 2>&1
          fi
        '';

        # Web apps (modules/home/programs/web-apps)
        programs.webApps.apps = {
          bitwarden-inboxcom = bitwarden "sebastian@corp.inbox.com" "bitwarden-work-sebastian.corp.inbox.com";
          bitwarden-inboxcom-post = bitwarden "post@corp.inbox.com" "bitwarden-work-post.corp.inbox.com";
          teams = {
            name = "Microsoft Teams (Work)";
            url = "https://teams.live.com/v2/";
            icon = ./icons/teams.svg;
            genericName = "Meetings";
            comment = "Video Conferencing, Meetings, Calling";
          };
          zoom = {
            name = "Zoom";
            url = "https://zoom.us";
            icon = ./icons/zoom.svg; # From the Papirus icon theme (GPL-3.0)
            genericName = "Meetings";
            comment = "Video Conferencing, Meetings, Calling";
          };
        };
      };
  };
}
