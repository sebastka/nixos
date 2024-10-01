{
  pkgs,
  ...
}: {
  services.tailscale.enable = false;

  systemd.services."ts@" = {
    description = "Tailscale node agent";
    documentation = [ "https://tailscale.com/kb/" ];
    wants = [ "network-pre.target" ];
    after = [ "network-pre.target" "NetworkManager.service" "systemd-resolved.service" ];
    conflicts = [ "tailscaled.service" "ts@.service" ];

    serviceConfig = {
      ExecStart= ''${pkgs.tailscale}/bin/tailscaled --statedir=/var/lib/tailscale/ts.%I --port=41641 --tun "tailscale0"'';
      ExecStopPost = ''${pkgs.tailscale}/bin/tailscaled --cleanup'';

      Restart = "on-failure";

      RuntimeDirectory = "tailscale";
      RuntimeDirectoryMode = "0755";
      StateDirectory = "tailscale";
      StateDirectoryMode = "0700";
      CacheDirectory = "tailscale";
      CacheDirectoryMode = "0750";
      Type = "notify";
    };
  };
}
