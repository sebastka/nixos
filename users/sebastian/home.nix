{ lib, pkgs, ... }:

{
  # Personal scripts (./scripts/<name>.sh), checked by shellcheck at build time
  home.packages =
    map
      (
        name:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [ pkgs.kubectl ];
          text = builtins.readFile ./scripts/${name}.sh;
        }
      )
      [
        "to_paperless"
        "to_deluge"
      ];

  # GnuPG keys live on Yubikeys (private primary keys are offline).
  # On a new machine, run `gpg --card-status` once per Yubikey to link the subkeys to the cards.
  programs.gpg = {
    settings.default-key = "0B25B26C537B40B5B208F3A6C74C02E66D0CBECF";
    publicKeys = [
      {
        source = ./keys/private.asc;
        trust = 5;
      } # sebastian@karlsen.fr, Yubikey ...40146785
      {
        source = ./keys/inboxcom.asc;
        trust = 5;
      } # sebastian@corp.inbox.com, Yubikey ...40146786
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
    # Work repositories (~/Dev/Work/): ./work.nix
  };

  # SSH keys: the OpenPGP authentication subkeys on the Yubikeys (private keys never leave the Yubikeys), exported
  # with `gpg --export-ssh-key <subkey>!`. Used through gpg-agent, see modules/nixos/desktop/gnupg.nix.
  home.file.".ssh/key/private.id_ed25519_gpg.pub".source = ./keys/private.id_ed25519_gpg.pub;
  home.file.".ssh/key/inboxcom.id_ed25519_gpg.pub".source = ./keys/inboxcom.id_ed25519_gpg.pub;

  # Personal SSH hosts (./ssh/config.d/*.conf; work hosts: a secret, see ./work.nix). Read before the blocks
  # below: the first value set for an option wins.
  programs.ssh.includes = [ "config.d/*.conf" ];
  home.file.".ssh/config.d" = {
    source = ./ssh/config.d;
    recursive = true; # Links each file: ./work.nix adds work.conf to the directory
  };
  # Host keys: common (GitHub, AUR) and private here, work a secret (./work.nix)
  home.file.".ssh/known_hosts.d" = {
    source = ./ssh/known_hosts.d;
    recursive = true;
  };

  programs.ssh.settings = {
    # Work servers: inboxcom Yubikey
    "*.fjordmail.no".IdentityFile = "~/.ssh/key/inboxcom.id_ed25519_gpg.pub";
    # Everything else: personal Yubikey
    "*".IdentityFile = "~/.ssh/key/private.id_ed25519_gpg.pub";
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
