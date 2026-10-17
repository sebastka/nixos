{ self, pkgs, ... }:

# KDE Plasma 6, with SDDM: a desktop environment, next to modules/nixos/desktop (one per host: this,
# modules/nixos/gnome or modules/nixos/cinnamon). Secrets: KWallet (also for libsecret), unlocked at login by SDDM's
# PAM.
{
  imports = [ self.inputs.plasma-nm-ts.nixosModules.default ];

  # Enable the X11 windowing system (also required for Wayland on most setups).
  services.xserver.enable = true;

  services.displayManager.sddm.enable = true;
  # Auto-unlock KWallet at login using the SDDM login password via PAM, so no separate passphrase is prompted.
  security.pam.services.sddm.kwallet.enable = true;
  services.desktopManager.plasma6.enable = true;
  # No Flatpak: Discover only installs Flatpaks and firmware here (its Flatpak backend creates
  # ~/.local/share/flatpak). Firmware updates stay available with fwupdmgr.
  environment.plasma6.excludePackages = [ pkgs.kdePackages.discover ];
  # Nor Plasma Browser Integration's Flatpak integrator, which writes its host into ~/.var/app/<browser> of known
  # Flatpak browsers at every login. A default for every user (/etc/xdg is in KDE's config path). kded5rc, even for
  # KF6's kded (it reads no kded6rc).
  environment.etc."xdg/kded5rc".text = ''
    [Module-browserintegrationflatpakintegrator]
    autoload=false
  '';

  # No file indexing (Baloo, part of Plasma): indexing off by default for every user (/etc/xdg, as kded5rc above),
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

  # Laptops: the low battery warning at 20 % (10 % by default), for every user (/etc/xdg, as kded5rc above). Its
  # critical level and action (5 %: sleep) stay. Charge thresholds: modules/nixos/desktop/battery.nix.
  environment.etc."xdg/powerdevilrc".text = ''
    [BatteryManagement]
    BatteryLowLevel=20
  '';

  # Tailscale profiles as NetworkManager VPN connections, in Plasma's network applet (testing, instead of KTailctl).
  # Tailscale itself: modules/nixos/desktop/tailscale.nix. Prototype: connections are made with nmcli, e.g.
  #   nmcli connection add type vpn vpn-type tailscale con-name "Tailscale (private)" vpn.data profile=karlsen.fr
  services.plasma-nm-ts.enable = true;

  environment.systemPackages = [ pkgs.kdePackages.kate ];

  home-manager.sharedModules = [
    ../../home/programs/dolphin
    # gpg-agent's PIN prompt (modules/nixos/desktop/gnupg.nix), Qt
    { services.gpg-agent.pinentry.package = pkgs.pinentry-qt; }
  ];
}
