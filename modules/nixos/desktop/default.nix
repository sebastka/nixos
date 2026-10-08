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

  # /etc/hosts as a file, not a link to the store: temporary entries with `sudo -e /etc/hosts`, effective at once,
  # until the next switch or boot rewrites it from networking.hosts (lasting entries go there).
  environment.etc.hosts.mode = "0644";
  networking.extraHosts = ''
    # 100.120.159.240  controller.do.fjordmail.no
    # 100.119.119.227  sandbox.do.fjordmail.no
    # 100.104.98.178   web.do.fjordmail.no
    # 68.183.243.94    whoami-public.web.do.fjordmail.no
  '';

  services.printing.enable = true;

  programs.firefox.enable = true;
  programs.thunderbird.enable = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kate
    libsecret # secret-tool: secrets in the keyring
    chromium # Also runs the web apps (modules/home/programs/web-apps)
  ];
}
