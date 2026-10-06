{ pkgs, ... }:

{
  # Tailscale on every desktop; sebastian can run tailscale up/down, switch tailnets... without sudo (KTailctl too)
  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [ "--operator=sebastian" ];

  # KTailctl: Tailscale in Plasma's system tray, started at login for every user
  environment.systemPackages = [ pkgs.ktailctl ];
  environment.etc."xdg/autostart/org.fkoehler.KTailctl.desktop".text = ''
    [Desktop Entry]
    Version=1.0
    Type=Application
    Name=KTailctl
    Comment=GUI for tailscale on the KDE Plasma desktop
    Exec=ktailctl
    Icon=org.fkoehler.KTailctl
    Terminal=false
    Categories=Qt;KDE;System;
    StartupNotify=false
  '';
}
