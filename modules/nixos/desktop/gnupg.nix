{ pkgs, ... }:

{
  # Smartcard daemon for the Yubikeys' OpenPGP applet (scdaemon uses it, see disable-ccid).
  services.pcscd.enable = true;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
    settings = {
      default-cache-ttl = 36000;
      max-cache-ttl = 36000;
    };
  };
}
