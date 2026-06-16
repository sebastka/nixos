{ pkgs, ... }:

{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-qt;
    settings = {
      default-cache-ttl = 36000;
      max-cache-ttl = 36000;
      default-cache-ttl-ssh = 36000;
      max-cache-ttl-ssh = 36000;
    };
  };
}
