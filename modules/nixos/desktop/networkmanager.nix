{
  config,
  lib,
  self,
  ...
}:

{
  networking.networkmanager.enable = true;
  # No mobile broadband modem (4G/5G) on our desktops: a host with one sets it back to true. Above NetworkManager's
  # mkDefault true, below a host's plain value.
  networking.modemmanager.enable = lib.mkOverride 900 false;

  # Env file with NM_<NETWORK>_PSK=... lines, desktop-only secrets (not readable by servers).
  sops.secrets."nm-wifi-env".sopsFile = "${self}/secrets/desktop.sops.yaml";

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."nm-wifi-env".path ];
    profiles."NETGEAR30" = {
      connection = {
        id = "NETGEAR30";
        uuid = "98e51fc9-e58f-42ec-9ad7-fc8f8cabd2bf";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "NETGEAR30";
        "cloned-mac-address" = "permanent"; # Hardware MAC, never randomized
      };
      "wifi-security" = {
        "key-mgmt" = "sae";
        psk = "$NM_NETGEAR30_PSK";
      };
      ipv4.method = "auto";
      ipv6 = {
        "addr-gen-mode" = "default";
        method = "auto";
      };
    };
    profiles."NETGEAR30-5G" = {
      connection = {
        id = "NETGEAR30-5G";
        uuid = "f1a2918f-4410-4a99-957a-3b43e92f68cd";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "NETGEAR30-5G";
        "cloned-mac-address" = "permanent"; # Hardware MAC, never randomized
      };
      "wifi-security" = {
        "key-mgmt" = "sae";
        psk = "$NM_NETGEAR30_5G_PSK";
      };
      ipv4.method = "auto";
      ipv6 = {
        "addr-gen-mode" = "default";
        method = "auto";
      };
    };
    profiles."sebastka-caiman" = {
      connection = {
        id = "sebastka-caiman";
        uuid = "7d065bf3-793b-4b15-a9dc-f00a660ce836";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "sebastka-caiman";
      };
      "wifi-security" = {
        "auth-alg" = "open";
        "key-mgmt" = "sae";
        psk = "$NM_SEBASTKA_CAIMAN_PSK";
      };
      ipv4.method = "auto";
      ipv6 = {
        "addr-gen-mode" = "default";
        method = "auto";
      };
    };
  };
}
