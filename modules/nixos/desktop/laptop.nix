{ lib, ... }:

{
  # Laptops (geras, boreas): their battery first, e.g. Bluetooth off at boot (./bluetooth.nix), rootless Docker not
  # started at login (users/<user>/desktop.nix)
  options.desktop.laptop.enable = lib.mkEnableOption "laptop defaults that spare the battery";
}
