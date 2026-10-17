{ pkgs-unstable, ... }:

{
  # Tailscale on every desktop; sebastian can run tailscale up/down, switch tailnets... without sudo. In the network
  # applet: modules/nixos/plasma (plasma-nm-ts).
  services.tailscale.enable = true;
  services.tailscale.package = pkgs-unstable.tailscale; # Self-contained, moves fast

  services.tailscale.extraSetFlags = [ "--operator=sebastian" ];
}
