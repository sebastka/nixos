{ lib, pkgs, ... }:

# Wake-on-LAN from helios, always on: `wake <host>` sends a magic packet to each MAC address of a host of ./lan.nix
# (mac and wakeMacs, e.g. both of zeus's cards: hosts/zeus/default.nix). To the LAN's broadcast address, not
# 255.255.255.255: out of br0 only, never the WAN. From elsewhere: ssh helios.home.karlsen.fr wake zeus (LAN, tailnet).
let
  lan = import ./lan.nix;
  wakeable = lib.filterAttrs (_: host: host ? mac) lan.hosts;

  wake = pkgs.writeShellApplication {
    name = "wake";
    runtimeInputs = [ pkgs.wakeonlan ];
    text = ''
      case "''${1:-}" in
      ${lib.concatStrings (
        lib.mapAttrsToList (
          name: host:
          "  ${name}) macs=\"${lib.concatStringsSep " " ([ host.mac ] ++ host.wakeMacs or [ ])}\" ;;\n"
        ) wakeable
      )}
        *)
          echo "Usage: wake <host>, one of: ${lib.concatStringsSep " " (lib.attrNames wakeable)}" >&2
          exit 1
          ;;
      esac
      # shellcheck disable=SC2086 # One argument per MAC address
      wakeonlan -i 192.168.255.255 $macs # The LAN: 192.168.0.0/16
    '';
  };
in
{
  environment.systemPackages = [ wake ];
}
