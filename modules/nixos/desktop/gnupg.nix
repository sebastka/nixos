{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Smartcard daemon for the Yubikeys' OpenPGP applet (scdaemon uses it, see disable-ccid).
  services.pcscd.enable = true;
  # Without -x (exit after 60 s idle, set by the module): scdaemon doesn't keep pcscd busy, and each exit resets
  # the Yubikeys, which then need their PIN again.
  systemd.services.pcscd.serviceConfig.ExecStart =
    let
      # As set by the module
      package = if config.security.polkit.enable then pkgs.pcscliteWithPolkit else pkgs.pcsclite;
      readerConf = config.environment.etc."reader.conf".source;
      extraArgs = lib.escapeShellArgs config.services.pcscd.extraArgs;
    in
    lib.mkForce [
      ""
      "${lib.getExe package} -f -c ${readerConf} ${extraArgs}"
    ];

  environment.systemPackages = [ pkgs.yubikey-manager ]; # ykman

  # GnuPG agent, also the SSH agent: SSH keys are the OpenPGP authentication subkeys on the Yubikeys, so signing,
  # decryption and SSH all go through scdaemon (PIN once). From home-manager: its sockets follow the GnuPG home
  # (~/.local/share/gnupg, modules/home/programs/gpg), the NixOS ones only the default ~/.gnupg.
  home-manager.sharedModules = [
    (
      { config, ... }:
      {
        services.gpg-agent = {
          enable = true;
          enableSshSupport = true;
          pinentry.package = pkgs.pinentry-qt;
          defaultCacheTtl = 36000;
          maxCacheTtl = 36000;
        };
        # GnuPG 2.4 sends the data to sign to scdaemon in one line, so the agent refuses more than ~476 bytes
        # ("General error", "agent refused operation" in ssh). SSH signs the server's host key too (publickey-
        # hostbound): an SSH certificate (*.home.karlsen.fr) is too large. Fixed in GnuPG 2.5, not in nixpkgs:
        # its two commits here, for the gpg and gpg-agent of the user only (patching pkgs.gnupg rebuilds a lot).
        # Remove once pkgs.gnupg is 2.5 or later.
        programs.gpg.package = pkgs.gnupg.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            # agent: Use SETDATA --apend for larger data to communicate scdaemon.
            (pkgs.fetchpatch {
              url = "https://github.com/gpg/gnupg/commit/fe147645d.patch";
              hash = "sha256-Kwlv9JRYEuJCZIs2k87L56PyMNNc4biF5yyujzPDDlA=";
            })
            # agent: Clean up for the refactoring.
            (pkgs.fetchpatch {
              url = "https://github.com/gpg/gnupg/commit/893e5e7c6.patch";
              hash = "sha256-zeVVcevRYpDfbvvVW5lLMDJGUS3HlOYOIcYACpJYs7A=";
            })
          ];
        });

        # For the whole session (graphical apps too), not only interactive shells (enableSshSupport)
        home.sessionVariablesExtra = ''
          export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
        '';
      }
    )
  ];
}
