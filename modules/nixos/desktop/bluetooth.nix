{ ... }:

# Bluetooth (BlueZ), on at boot. The desktop environment's Bluetooth settings come with it; headsets' audio goes through
# PipeWire (./audio.nix). Pairings are kept in /var/lib/bluetooth (persisted on geras: hosts/geras/impermanence.nix).
{
  hardware.bluetooth.enable = true;
}
