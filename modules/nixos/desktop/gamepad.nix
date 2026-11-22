{ pkgs, ... }:

# Xbox controllers (One S and later, Series X|S)
{
  # Over Bluetooth (./bluetooth.nix): xpadneo instead of the kernel's generic HID driver, for rumble, the same mapping in
  # every game, and the battery level in the desktop environment. An out-of-tree module, built for each kernel.
  hardware.xpadneo.enable = true;

  # With Microsoft's USB wireless dongle (USB-A): xone, the kernel has no driver for it. Its firmware is unfree. x86 only
  # (boreas has USB-C only, and pairs over Bluetooth). Blacklists xpad (wired controllers: replaced by xpad-noone) and
  # mt76x2u (a MediaTek USB Wi-Fi driver, unused here).
  hardware.xone.enable = pkgs.stdenv.hostPlatform.isx86_64;
}
