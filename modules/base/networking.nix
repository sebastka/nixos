{
  lib,
  ...
}: {
  networking.nftables.enable = true;
  systemd.network.enable = lib.mkDefault true;
  networking.nameservers = [ "1.1.1.1#one.one.one.one" "1.0.0.1#one.one.one.one" ];
  services.resolved.enable = true;
  services.resolved.dnssec = "true";
  services.resolved.fallbackDns = [ "8.8.8.8#dns.google" "8.8.4.4#dns.google" ];
  services.resolved.dnsovertls = "true";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  # networking.nftables.enable = true;
}
