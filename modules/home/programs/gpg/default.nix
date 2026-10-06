{ config, ... }:

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
}
