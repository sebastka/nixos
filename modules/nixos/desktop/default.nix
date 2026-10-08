{ lib, pkgs, ... }:

{
  imports = [
    ./audio.nix
    ./docker.nix
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
  ];

  # Norwegian keyboard by default, as the console (modules/nixos/common)
  services.xserver.xkb.layout = lib.mkDefault "no";

  services.printing.enable = true;

  programs.firefox.enable = true;
  programs.thunderbird.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    libsecret # secret-tool: secrets in the keyring
    chromium # Also runs the web apps (modules/home/programs/web-apps)
  ];
}
