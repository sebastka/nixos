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
    {
      settings = {
        "org/cinnamon/settings-daemon/plugins/power".percentage-low = lib.gvariant.mkInt32 20;
        # Night light, from sunset to sunrise (auto: from the timezone)
        "org/cinnamon/settings-daemon/plugins/color" = {
          night-light-enabled = true;
          night-light-schedule-mode = "auto";
        };
      };
    }
  ];

  home-manager.sharedModules = [
    # gpg-agent's PIN prompt (modules/nixos/desktop/gnupg.nix), GTK
    { services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3; }

    # The session variables (home.sessionVariables: CLAUDE_CONFIG_DIR, CODEX_HOME, GNUPGHOME…) in the session, so in
    # the apps launched from it: LightDM's session wrapper is bash, sourcing ~/.profile and ~/.xprofile, never zsh's
    # ~/.zshenv (SDDM, on Plasma, runs the login shell). Not xsession.enable: it would also write a ~/.xsession.
    (
      { config, ... }:
      {
        home.file.".xprofile".text = ''
          . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        '';
      }
    )
  ];
}
