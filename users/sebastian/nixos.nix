{
  # NixOS Configuration

  users.users.sebastian = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZmslJoq+Noss24qK0p+FV9LzvOzWhV7v8m9ahJ4uGT sebastian@fjordmail-xps15.home.karlsen.fr"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKw42V/vEj+UrBy1zcVKubbdkZEVSjzr1W5yWfX2cjdL sebastian@zeus.home.karlsen.fr"
    ];
  };
}
