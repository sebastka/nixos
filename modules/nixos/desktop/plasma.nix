{ pkgs, ... }:

{
  # Enable the X11 windowing system (also required for Wayland on most setups).
  services.xserver.enable = true;

  # KDE Plasma 6 with SDDM display manager.
  services.displayManager.sddm.enable = true;
  # Auto-unlock KWallet at login using the SDDM login password via PAM, so no separate passphrase is prompted.
  security.pam.services.sddm.kwallet.enable = true;
  services.desktopManager.plasma6.enable = true;
  # No Flatpak: Discover only installs Flatpaks and firmware here (its Flatpak backend creates
  # ~/.local/share/flatpak). Firmware updates stay available with fwupdmgr.
  environment.plasma6.excludePackages = [ pkgs.kdePackages.discover ];
  # Nor Plasma Browser Integration's Flatpak integrator, which writes its host into ~/.var/app/<browser> of known
  # Flatpak browsers at every login. A default for every user (/etc/xdg is in KDE's config path).
  environment.etc."xdg/kded6rc".text = ''
    [Module-browserintegrationflatpakintegrator]
    autoload=false
  '';

  # No file indexing (Baloo, part of Plasma): indexing off by default for every user (/etc/xdg, as kded6rc above),
  # its service masked, and file search off in KRunner and the launcher (they would query an empty index)
  environment.etc."xdg/baloofilerc".text = ''
    [Basic Settings]
    Indexing-Enabled=false
  '';
  systemd.user.services.kde-baloo.enable = false;
  environment.etc."xdg/krunnerrc".text = ''
    [Plugins]
    baloosearchEnabled=false
  '';

  # No push notification relay (KUnifiedPush, part of Plasma): for apps like NeoChat or Tokodon, none installed
  systemd.user.services.kunifiedpush-distributor.enable = false;

  # No screen reader (Orca, on with Plasma), nor speech synthesis (speech-dispatcher, which Orca requires): unused.
  # Started by Firefox listing voices, speech-dispatcher left a zombie per speech engine it probed without having it.
  services.orca.enable = false;
  services.speechd.enable = false;
}
