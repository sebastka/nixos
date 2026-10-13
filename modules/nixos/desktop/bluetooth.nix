{ ... }:

# Bluetooth (BlueZ), on at boot. Plasma's Bluetooth settings and tray applet come with it; headsets' audio goes through
# PipeWire (./audio.nix). Pairings are kept in /var/lib/bluetooth (persisted on geras: hosts/geras/impermanence.nix).
{
  hardware.bluetooth.enable = true;
}
