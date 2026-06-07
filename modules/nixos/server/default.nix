{ ... }:

{
  networking.useDHCP = false;
  networking.useNetworkd = true;
  services.resolved.enable = true;
}
