{ lib, ... }:

{
  # GnuPG keys live on Yubikeys (private primary keys are offline).
  # On a new machine, run `gpg --card-status` once per Yubikey to link the subkeys to the cards.
  programs.gpg = {
    settings.default-key = "0B25B26C537B40B5B208F3A6C74C02E66D0CBECF";
    publicKeys = [
      { source = ./keys/private.asc; trust = 5; } # sebastian@karlsen.fr, Yubikey ...40146785
      { source = ./keys/inboxcom.asc; trust = 5; } # sebastian@corp.inbox.com, Yubikey ...40146786
    ];
  };

  programs.git = {
    signing = {
      format = "openpgp";
      key = "0B25B26C537B40B5B208F3A6C74C02E66D0CBECF";
      signByDefault = true;
    };
    settings = {
      user.name = "Sebastian Karlsen";
      user.email = "sebastian@karlsen.fr";
    };

    # Work repositories: inboxcom identity, signing key and SSH key for GitHub
    # (same host as personal repos, GitHub picks the account from the SSH key).
    includes = [
      {
        condition = "gitdir:~/Dev/Work/";
        contents = {
          user.email = "sebastian@corp.inbox.com";
          user.signingKey = "6908E0776A37F2BAAC4E192FE361F48DB812586F";
          core.sshCommand = "ssh -i ~/.ssh/key/inboxcom.id_ed25519_piv.pub";
        };
      }
    ];
  };

  # SSH keys in the Yubikeys' PIV slot 9a (private keys never leave the Yubikeys).
  # Used through the agent after `ssh-add-yubikey` (no PIN, no touch), see modules/home/programs/ssh.
  home.file.".ssh/key/private.id_ed25519_piv.pub".source = ./keys/private.id_ed25519_piv.pub;
  home.file.".ssh/key/inboxcom.id_ed25519_piv.pub".source = ./keys/inboxcom.id_ed25519_piv.pub;

  # Personal SSH hosts (./ssh/config.d/*.conf; work hosts: a secret, see ./desktop.nix). Read before the blocks
  # below: the first value set for an option wins.
  programs.ssh.includes = [ "config.d/*.conf" ];
  home.file.".ssh/config.d" = {
    source = ./ssh/config.d;
    recursive = true; # Links each file: ./desktop.nix adds work.conf to the directory
  };
  # Host keys: common (GitHub, AUR) and private here, work a secret (./desktop.nix)
  home.file.".ssh/known_hosts.d" = {
    source = ./ssh/known_hosts.d;
    recursive = true;
  };

  programs.ssh.settings = {
    # Work servers: inboxcom Yubikey
    "*.fjordmail.no".IdentityFile = "~/.ssh/key/inboxcom.id_ed25519_piv.pub";
    # Everything else: personal Yubikey
    "*".IdentityFile = "~/.ssh/key/private.id_ed25519_piv.pub";
    # Writable file first: ssh saves new host keys there (the others are read-only, missing ones are skipped)
    "*".UserKnownHostsFile = lib.concatMapStringsSep " " (f: "~/.ssh/${f}") [
      "known_hosts"
      "known_hosts.d/common"
      "known_hosts.d/private"
      "known_hosts.d/inboxcom"
    ];
  };

  home.stateVersion = "26.05";
}
