{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  # Chromium's key (its saved passwords and cookies) in the Secret Service on every desktop environment, through
  # libsecret: by default, its KWallet API on Plasma. The same item whatever the keyring (KWallet, GNOME Keyring), so it
  # follows with bin/keyring-export and bin/keyring-import. Only its wrapper changes: the browser stays cached.
  chromium = pkgs.chromium.override { commandLineArgs = "--password-store=gnome-libsecret"; };
in

{
  imports = [
    ./audio.nix
    ./battery.nix
    ./bluetooth.nix
    ./docker.nix
    ./fonts.nix
    ./gnupg.nix
    ./networkmanager.nix
    ./syncthing.nix
    ./tailscale.nix
    ./tern.nix
  ];

  # User configuration for every user on desktops (home-manager)
  home-manager.sharedModules = [
    { programs.webApps.package = chromium; }
    ../../home/programs/coding-agents
    ../../home/programs/node
    ../../home/programs/ops
    ../../home/programs/vscode
    # ../../home/programs/zed
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
    # 129.212.170.25   whoami-public.controller.do.fjordmail.no
    # XXX              whoami-public.sandbox.do.fjordmail.no
    # 68.183.243.94    whoami-public.web.do.fjordmail.no
  '';

  services.printing.enable = true;

  # No screen reader (Orca, on with Plasma and GNOME), nor speech synthesis (speech-dispatcher, which Orca requires):
  # unused. Started by Firefox listing voices, speech-dispatcher left a zombie per speech engine it probed without
  # having it.
  services.orca.enable = false;
  services.speechd.enable = false;

  programs.firefox.enable = true;
  programs.thunderbird.enable = true;

  environment.systemPackages = with pkgs; [
    libsecret # secret-tool: secrets in the keyring
    chromium # Also runs the web apps (modules/home/programs/web-apps, above)
    pkgs-unstable.telegram-desktop # Self-contained, moves fast (stable lags a release behind)
    php # The CLI (php), with its default extensions
    php.packages.composer # Built on the php above
    # Its latest release (nixpkgs lags behind), x86_64 and arm64, with the system's fonts in its documents
    (callPackage ../../../pkgs/onlyoffice-desktopeditors { fonts = config.fonts.packages; })
  ];
}
