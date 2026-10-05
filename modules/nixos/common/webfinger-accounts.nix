{ config, lib, pkgs, ... }:

# users.users.<name>.webfinger = "<account>@<domain>": the user's email and picture, as shown by desktops and display
# managers (Plasma, GNOME, SDDM, GDM, LightDM), from the account's WebFinger profile (its mailto: alias and avatar
# link). Set through AccountsService at boot, so a changed avatar is picked up. Offline, the previous ones stay.
# Only where AccountsService runs (enabled by Plasma, GNOME and others): servers ignore it.
let
  setFromWebFinger = pkgs.writeShellApplication {
    name = "accounts-webfinger";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.systemd ];
    text = ''
      user=$1 address=$2
      curl() { command curl -fsS --retry 10 --retry-all-errors "$@"; }
      finger=$(curl --get --data-urlencode "resource=acct:$address" "https://''${address#*@}/.well-known/webfinger")

      account=$(busctl --json=short call org.freedesktop.Accounts /org/freedesktop/Accounts \
        org.freedesktop.Accounts FindUserByName s "$user" | jq -r '.data[0]')
      set_user() { busctl call org.freedesktop.Accounts "$account" org.freedesktop.Accounts.User "$@"; }

      if email=$(jq -er '[.aliases[]? | select(startswith("mailto:"))][0] | ltrimstr("mailto:")' <<<"$finger"); then
        set_user SetEmail s "$email"
      fi
      if avatar=$(jq -er '[.links[]? | select(.rel == "http://webfinger.net/rel/avatar")][0].href' <<<"$finger"); then
        curl -o "$RUNTIME_DIRECTORY/avatar" "$avatar"
        set_user SetIconFile s "$RUNTIME_DIRECTORY/avatar" # Copied to /var/lib/AccountsService/icons/<user>
      fi
    '';
  };

  users = lib.filterAttrs (_: user: user.webfinger != null) config.users.users;
in
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.webfinger = lib.mkOption {
          type = lib.types.nullOr (lib.types.strMatching "[^@]+@[^@]+");
          default = null;
          example = "alice@example.org";
          description = "WebFinger account whose email and avatar are set as the user's (AccountsService).";
        };
      }
    );
  };

  config = lib.mkIf config.services.accounts-daemon.enable {
    systemd.services = lib.mapAttrs' (
      name: user:
      lib.nameValuePair "accounts-webfinger-${name}" {
        description = "Email and picture of ${name} from WebFinger";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" "accounts-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe setFromWebFinger} ${lib.escapeShellArgs [ name user.webfinger ]}";
          RuntimeDirectory = "accounts-webfinger-${name}";
        };
      }
    ) users;
  };
}
