{ pkgs, ... }:

# GNOME, with GDM: a desktop environment, next to modules/nixos/desktop (one per host: this or modules/nixos/plasma).
# Wayland only. Secrets: GNOME Keyring (libsecret), unlocked at login by GDM's PAM.
# TODO: Tailscale in the network menu, as plasma-nm-ts in modules/nixos/plasma.
let
  # With GNOME Classic (upstream's classic_mode, which nixpkgs leaves out): its session, shell mode (classic.json:
  # the window list, Applications and Places menus...) and settings, next to the extensions themselves
  gnome-shell-extensions = pkgs.gnome-shell-extensions.overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or [ ]) ++ [ "-Dclassic_mode=true" ];
    passthru = (old.passthru or { }) // {
      providedSessions = [ "gnome-classic" ];
    };
  });
in
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # GNOME Classic, in GDM's session menu (the gear, bottom right, after choosing the user)
  services.displayManager.sessionPackages = [ gnome-shell-extensions ];
  services.desktopManager.gnome.sessionPath = [ gnome-shell-extensions ]; # Its extensions and settings
  systemd.packages = [ gnome-shell-extensions ]; # Its gnome-session@gnome-classic.target drop-in

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

  # Log Out in the system menu always, even for a single user without other sessions (GNOME hides it then). Locked:
  # every user, whatever their own settings.
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/shell".always-show-log-out = true;
      locks = [ "/org/gnome/shell/always-show-log-out" ];
    }
  ];

  # gpg-agent's PIN prompt (modules/nixos/desktop/gnupg.nix), GTK
  home-manager.sharedModules = [ { services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3; } ];
}
