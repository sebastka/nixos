{ lib, pkgs, ... }:

# Disk health (SMART): smartctl, and smartd watching every disk it finds. Its findings (failing attributes, errors,
# failed self-tests) go to the journal (journalctl -u smartd), and to logged-in users (wall). Not on hosts without a
# SMART disk (hermes: an SD card), where smartd would find nothing and fail.
{
  environment.systemPackages = [ pkgs.smartmontools ]; # sudo smartctl -a /dev/sda

  services.smartd = {
    enable = lib.mkDefault true; # Off on hosts without SMART disks
    # Every disk: all attributes and logs (-a), the drive's own offline data collection (-o on), and self-tests: short
    # every night at 03:00, long on Sundays at 04:00 (online: the disk keeps working; before the upgrades' reboots)
    defaults.autodetected = "-a -o on -s (S/../.././03|L/../../7/04)";
  };
}
