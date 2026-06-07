{ pkgs, ... }:

{
  home.packages = [ pkgs.ktailctl ];

  xdg.configFile."autostart/org.fkoehler.KTailctl.desktop".text = ''
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
