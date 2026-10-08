{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  # The user's email (users.users.<name>.email, modules/nixos/common/user-email.nix)
  email = osConfig.users.users.${config.home.username}.email or null;
in
{
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    settings = {
      keyserver = "hkps://keyserver.ubuntu.com";
      keyserver-options = "no-honor-keyserver-url auto-key-retrieve";
      keyid-format = "0xlong";
      with-fingerprint = true;
      default-recipient-self = true;
      personal-cipher-preferences = "AES256";
      personal-digest-preferences = "SHA512";
      cert-digest-algo = "SHA512";
    };

    # Talk to the Yubikeys through pcscd (services.pcscd), instead of scdaemon's own USB driver,
    # and don't lock the card: other tools (ykman) can use it at the same time.
    # Only the OpenPGP application: otherwise the card's authentication key for SSH was the PIV one (slot 9a),
    # which gpg-agent hands to ssh in a format it can't read ("error fetching identities: invalid format").
    scdaemonSettings = {
      disable-ccid = true;
      pcsc-shared = true;
      disable-application = "piv";
    };
  };

  # The email's OpenPGP key, as its domain publishes it (WKD, then its OPENPGPKEY DNS record: DANE), in the keyring at
  # each login: imported, or updated (new subkeys, expiry), its trust unchanged. Offline: the keyring stays as is.
  systemd.user.services.gpg-email-key = lib.mkIf (email != null) {
    Unit.Description = "OpenPGP key of ${email} (WKD, DANE)";
    Service = {
      Type = "oneshot";
      Environment = [ "GNUPGHOME=${config.programs.gpg.homedir}" ];
      ExecStart = toString (
        pkgs.writeShellScript "gpg-email-key" ''
          for _ in 1 2 3 4 5 6; do
            if ${lib.getExe config.programs.gpg.package} --batch --auto-key-locate clear,wkd,dane,nodefault \
              --locate-external-keys ${lib.escapeShellArg email}; then
              exit 0
            fi
            sleep 10
          done
          echo "OpenPGP key of ${email} not found (offline?)" >&2
        ''
      );
    };
    Install.WantedBy = [ "default.target" ];
  };
}
