{ lib, pkgs, ... }:

# Cinnamon (Linux Mint's desktop), with LightDM and its slick greeter: a desktop environment, next to
# modules/nixos/desktop (one per host: this, modules/nixos/gnome or modules/nixos/plasma). X11; its Wayland session
# (cinnamon-wayland) is experimental, in the greeter's session menu. Secrets: GNOME Keyring (libsecret), unlocked at
# login by LightDM's PAM (through login's).
# TODO: Tailscale in the network applet (nm-applet), as plasma-nm-ts in modules/nixos/plasma.
{
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;
  services.displayManager.defaultSession = "cinnamon";

  # SSH keys stay with gpg-agent (modules/nixos/desktop/gnupg.nix): not GNOME Keyring's SSH agent, which would take
  # SSH_AUTH_SOCK.
  services.gnome.gcr-ssh-agent.enable = false;

  # Laptops: the low battery warning at 20 % (10 % by default), for every user, as Plasma's (modules/nixos/plasma).
  # Its critical level and action (4 %, then 3 %: hibernate) stay. Charge thresholds: modules/nixos/desktop/battery.nix.
  programs.dconf.profiles.user.databases = [
    { settings."org/cinnamon/settings-daemon/plugins/power".percentage-low = lib.gvariant.mkInt32 20; }
  ];

  # gpg-agent's PIN prompt (modules/nixos/desktop/gnupg.nix), GTK
  home-manager.sharedModules = [ { services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3; } ];
}
