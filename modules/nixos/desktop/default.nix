{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  imports = [
    ./audio.nix
    ./fonts.nix
    ./gnupg.nix
    ./networkmanager.nix
    ./plasma.nix
    ./tailscale.nix
    # ./tern.nix # Disabled
  ];

  # User configuration for every user on desktops (home-manager)
  home-manager.sharedModules = [
    ../../home/programs/coding-agents
    ../../home/programs/ops
    ../../home/programs/vscode
    { programs.webApps.package = pkgs-unstable.chromium; } # The one installed below
  ];

  # Norwegian keyboard by default, as the console (modules/nixos/common)
  services.xserver.xkb.layout = lib.mkDefault "no";

  services.printing.enable = true;

  programs.firefox.enable = true;
  programs.thunderbird = {
    enable = true;
    package = pkgs-unstable.thunderbird;
  };

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    libsecret # secret-tool: secrets in the keyring
    pkgs-unstable.chromium # Also runs the web apps (modules/home/programs/web-apps)
  ];
}
