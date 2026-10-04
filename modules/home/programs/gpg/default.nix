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
    # and don't lock the card: the SSH agent uses its PIV keys (libykcs11) at the same time.
    scdaemonSettings = {
      disable-ccid = true;
      pcsc-shared = true;
    };
  };
}
