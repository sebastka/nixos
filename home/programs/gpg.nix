{
  pkgs,
  ...
}:
{
  ## GPG CLI
  programs.gpg.enable = true;
  programs.gpg.settings.keyserver = "hkps://keyserver.ubuntu.com";
  programs.gpg.settings.keyserver-options = [ "no-honor-keyserver-url" "auto-key-retrieve" ];
  # Don't rely on short key IDs
  programs.gpg.settings.keyid-format = "0xlong";
  programs.gpg.settings."with-fingerprint" = true;
  # Default key
  # programs.gpg.settings.default-key = "XXX";
  programs.gpg.settings.default-recipient-self = true;
  # Strong hash by default
  programs.gpg.settings.personal-cipher-preferences = "AES256";
  programs.gpg.settings.personal-digest-preferences = "SHA512";
  programs.gpg.settings.cert-digest-algo = "SHA512";

  ## GPG Agent
  services.gpg-agent.enable = true;
  services.gpg-agent.defaultCacheTtl = 60 * 60 * 12;
  services.gpg-agent.maxCacheTtl = 60 * 60 * 24;
  services.gpg-agent.enableExtraSocket = true;
  services.gpg-agent.pinentryPackage = pkgs.pinentry-curses;
}
