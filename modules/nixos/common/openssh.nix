{ lib, ... }:

{
  # Pre-generated host keys (see secrets/*-ssh-host-key.sops.yaml), trusted on every host.
  programs.ssh.knownHosts.geras = {
    hostNames = [ "geras" "geras.home.karlsen.fr" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN5F4tGsBn04q+EMOlVyawiG+bn5+hL83bv6aOXfdsxf";
  };
  programs.ssh.knownHosts.zeus = {
    hostNames = [ "zeus" "zeus.home.karlsen.fr" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH6Tk9DVEvUXDG1oqQMakL9wd5FCUgcfXQ1TQtBIs8OL";
  };

  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      LoginGraceTime = 10; # Leaves time for the Yubikey touch (sk keys)
      MaxAuthTries = 3;
    };
    extraConfig = ''
      AllowTcpForwarding no
      AllowAgentForwarding no
      ChannelTimeout *=2h
      UnusedConnectionTimeout 1m
      PrintMotd no

      # SSH CA: uncomment once CA infrastructure is in place
      # TrustedUserCAKeys /etc/ssh/user_ca_key.pub
      # RevokedKeys /etc/ssh/revoked_keys
      # HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
    '';
  };
}
