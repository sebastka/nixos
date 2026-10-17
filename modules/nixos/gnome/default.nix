{ pkgs, ... }:

# GNOME, with GDM: a desktop environment, next to modules/nixos/desktop (one per host: this or modules/nixos/plasma).
# Wayland only. Secrets: GNOME Keyring (libsecret), unlocked at login by GDM's PAM.
# TODO: Tailscale in the network menu, as plasma-nm-ts in modules/nixos/plasma.
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Not needed: Firefox is the browser (modules/nixos/desktop), and the tour on first login
  environment.gnome.excludePackages = [
    pkgs.epiphany
    pkgs.gnome-tour
  ];
  # Nor the first login's setup (language, keyboard, online accounts): users are made by this configuration
  services.gnome.gnome-initial-setup.enable = false;

  # No file indexing (LocalSearch with TinySPARQL, as Baloo in Plasma): Nautilus and the overview's search look
  # through files by name, without an index.
  services.gnome.localsearch.enable = false;
  services.gnome.tinysparql.enable = false;

  # SSH keys stay with gpg-agent (modules/nixos/desktop/gnupg.nix): not GNOME Keyring's SSH agent, which would take
  # SSH_AUTH_SOCK.
  services.gnome.gcr-ssh-agent.enable = false;

  # gpg-agent's PIN prompt (modules/nixos/desktop/gnupg.nix), GTK
  home-manager.sharedModules = [ { services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3; } ];
}
