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

  # Linux Mint's wallpaper packs (./mint-backgrounds.nix), in System Settings > Backgrounds, one collection per pack
  environment.systemPackages = [ (pkgs.callPackage ./mint-backgrounds.nix { }) ];
  # Backgrounds' system collections from the system's lists (/run/current-system/sw/share), as from /usr/share on
  # Mint. nixpkgs' rewrite of /usr/share/cinnamon (to the package's own share/cinnamon) also catches
  # /usr/share/cinnamon-background-properties: a directory no package installs into, so none showed. Rebuilds Cinnamon.
  nixpkgs.overlays = [
    (final: prev: {
      cinnamon = prev.cinnamon.overrideAttrs (old: {
        postPatch = old.postPatch + ''
          substituteInPlace files/usr/share/cinnamon/cinnamon-settings/modules/cs_backgrounds.py --replace-fail \
            "$out/share/cinnamon-background-properties" "/run/current-system/sw/share/cinnamon-background-properties"
        '';
      });
    })
  ];

  # Laptops: the low battery warning at 20 % (10 % by default), for every user, as Plasma's (modules/nixos/plasma).
  # Its critical level and action (4 %, then 3 %: hibernate) stay. Charge thresholds: modules/nixos/desktop/battery.nix.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/cinnamon/settings-daemon/plugins/power".percentage-low = lib.gvariant.mkInt32 20;
        # Hack as the monospace font (modules/nixos/desktop/fonts.nix), as on Plasma, instead of DejaVu Sans Mono
        "org/gnome/desktop/interface".monospace-font-name = "Hack 10";
        # GNOME Terminal (Cinnamon's), its default profile: VS Code's terminal colours (Dark Modern: its panel's grey,
        # #CCCCCC text, VS Code's dark ANSI palette), instead of the theme's black and the Tango palette (dark blue on
        # black: the prompt's host name, ls' directories). Bold in the bright colours: VS Code raises low-contrast
        # colours (minimumContrastRatio), GNOME Terminal can't; the prompt's bold blue (starship) gets #3B8EEA so.
        "org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9" = {
          use-theme-colors = false;
          background-color = "#181818";
          foreground-color = "#CCCCCC";
          bold-is-bright = true;
          palette = [
            "#000000" # Black
            "#CD3131" # Red
            "#0DBC79" # Green
            "#E5E510" # Yellow
            "#2472C8" # Blue
            "#BC3FBC" # Magenta
            "#11A8CD" # Cyan
            "#E5E5E5" # White
            "#666666" # Bright black
            "#F14C4C" # Bright red
            "#23D18B" # Bright green
            "#F5F543" # Bright yellow
            "#3B8EEA" # Bright blue
            "#D670D6" # Bright magenta
            "#29B8DB" # Bright cyan
            "#E5E5E5" # Bright white
          ];
        };
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
