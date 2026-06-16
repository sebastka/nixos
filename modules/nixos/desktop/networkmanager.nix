{ config, ... }:

{
  networking.networkmanager.enable = true;

  sops.secrets."nm-wifi-env" = { };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."nm-wifi-env".path ];
    profiles."NETGEAR30-5G" = {
      connection = {
        id = "NETGEAR30-5G";
        uuid = "f1a2918f-4410-4a99-957a-3b43e92f68cd";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "NETGEAR30-5G";
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
