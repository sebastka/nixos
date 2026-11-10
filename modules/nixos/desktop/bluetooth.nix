{ config, ... }:

# Bluetooth (BlueZ), on at boot, but on laptops (./laptop.nix): off, turned on from the desktop environment when needed
# (Plasma's applet may still restore its state from the previous session). The desktop environment's Bluetooth settings
# come with it; headsets' audio goes through PipeWire (./audio.nix). Pairings are kept in /var/lib/bluetooth (persisted
# on geras: hosts/geras/impermanence.nix).
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = !config.desktop.laptop.enable;
  };
}
