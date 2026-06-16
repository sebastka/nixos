{ lib, ... }:

{
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
      LoginGraceTime = 5;
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
