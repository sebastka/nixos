{ pkgs, nix-claude-code, ... }:

{
  nixpkgs.overlays = [ nix-claude-code.overlays.default ];

  # Enable the X11 windowing system (also required for Wayland on most setups).
  services.xserver.enable = true;

  # KDE Plasma 6 with SDDM display manager.
  services.displayManager.sddm.enable = true;
  # Auto-unlock KWallet at login using the SDDM login password via PAM, so no separate passphrase is prompted.
  security.pam.services.sddm.kwallet.enable = true;
  services.desktopManager.plasma6.enable = true;

  networking.networkmanager.enable = true;
  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.firefox.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-curses;
    settings = {
      default-cache-ttl = 36000;
      max-cache-ttl = 36000;
    };
  };

  fonts.packages = with pkgs; [
    noto-fonts # broad Unicode coverage, good base font set
    noto-fonts-cjk-sans # Chinese, Japanese, Korean
    noto-fonts-color-emoji # emoji
    font-awesome # icon font used by many apps and themes
  ];

  programs.nix-ld.enable = true; # Allow dynamically-linked binaries from outside nixpkgs (e.g. VS Code extension bundled binaries)
  # programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];

  nixpkgs.config.permittedInsecurePackages = [
    "electron-39.8.10" # required by bitwarden-desktop; revisit when nixpkgs updates it
  ];
}
