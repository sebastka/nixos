{
  username,
  ...
}: {
  systemd.network.enable = false;
  networking.networkmanager.enable = true;
  # networking.networkmanager.dns = "systemd-resolved";
  users.users.${username}.extraGroups = [ "networkmanager" ];
}
