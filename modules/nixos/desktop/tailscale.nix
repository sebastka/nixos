{ self, ... }:

{
  imports = [ self.inputs.plasma-nm-ts.nixosModules.default ];

  # Tailscale on every desktop; sebastian can run tailscale up/down, switch tailnets... without sudo
  services.tailscale.enable = true;
  services.tailscale.extraSetFlags = [ "--operator=sebastian" ];

  # Tailscale profiles as NetworkManager VPN connections, in Plasma's network applet (testing, instead of KTailctl).
  # Prototype: connections are made with nmcli, e.g.
  #   nmcli connection add type vpn vpn-type tailscale con-name "Tailscale (private)" vpn.data profile=karlsen.fr
  services.plasma-nm-ts.enable = true;
}
