{
  config,
  lib,
  pkgs,
  ...
}:

# users.users.<name>.email: the user's email, and picture (the avatar of the address's WebFinger profile, if any), as
# shown by desktops and display managers (Plasma, GNOME, SDDM, GDM, LightDM). Set through AccountsService at boot,
# so a changed avatar is picked up. Offline, the previous picture stays.
# Only where AccountsService runs (enabled by Plasma, GNOME and others): servers ignore it.
let
  setEmail = pkgs.writeShellApplication {
    name = "user-email";
    runtimeInputs = [
      pkgs.curl
      pkgs.jq
      pkgs.systemd
    ];
    text = ''
      user=$1 email=$2
      account=$(busctl --json=short call org.freedesktop.Accounts /org/freedesktop/Accounts \
        org.freedesktop.Accounts FindUserByName s "$user" | jq -r '.data[0]')
      set_user() { busctl call org.freedesktop.Accounts "$account" org.freedesktop.Accounts.User "$@"; }

      set_user SetEmail s "$email"

      # Picture: the avatar link of the address's WebFinger profile (https://<domain>/.well-known/webfinger)
      curl() { command curl -fsS --retry 10 --retry-all-errors "$@"; }
      finger=$(curl --get --data-urlencode "resource=acct:$email" "https://''${email#*@}/.well-known/webfinger")
      if avatar=$(jq -er '[.links[]? | select(.rel == "http://webfinger.net/rel/avatar")][0].href' <<<"$finger"); then
        curl -o "$RUNTIME_DIRECTORY/avatar" "$avatar"
        set_user SetIconFile s "$RUNTIME_DIRECTORY/avatar" # Copied to /var/lib/AccountsService/icons/<user>
      fi
    '';
  };

  users = lib.filterAttrs (_: user: user.email != null) config.users.users;
in
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.email = lib.mkOption {
          type = lib.types.nullOr (lib.types.strMatching "[^@]+@[^@]+");
          default = null;
          example = "alice@example.org";
          description = "The user's email (AccountsService), and picture from its WebFinger profile.";
        };
      }
    );
  };

  config = lib.mkIf config.services.accounts-daemon.enable {
    systemd.services = lib.mapAttrs' (
      name: user:
      lib.nameValuePair "user-email-${name}" {
        description = "Email and picture of ${name}";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "accounts-daemon.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe setEmail} ${
            lib.escapeShellArgs [
              name
              user.email
            ]
          }";
          RuntimeDirectory = "user-email-${name}";
        };
      }
    ) users;
  };
}
