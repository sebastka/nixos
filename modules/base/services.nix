{
  # OpenSSH
  services.openssh.enable = true;
  services.openssh.settings.X11Forwarding = false;
  services.openssh.settings.PermitRootLogin = "no";
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.AuthorizedKeysFile = "/etc/ssh/authorized_keys.d/%u";

  # services.power-profiles-daemon.enable = true;
  #security.polkit.enable = true;
}
