{
  config,
  lib,
  pkgs,
  ...
}:

# users.users.<name>.email: the user's email, as shown by desktops and display managers (Plasma, GNOME, SDDM, GDM,
# LightDM), with a picture: the address's avatar, if any. Set through AccountsService at boot, so a changed avatar is
# picked up. Offline, the previous picture stays.
# Only where AccountsService runs (enabled by Plasma, GNOME and others): servers ignore it.
# Its OpenPGP key goes into the user's GnuPG keyring: modules/home/programs/gpg.
let
  setEmail = pkgs.writeShellApplication {
    name = "user-email";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.dig
      pkgs.file
      pkgs.getent
      pkgs.jq
      pkgs.systemd
    ];
    text = ''
      user=$1 email=$2 domain=''${2#*@}
      account=$(busctl --json=short call org.freedesktop.Accounts /org/freedesktop/Accounts \
        org.freedesktop.Accounts FindUserByName s "$user" | jq -r '.data[0]')
      set_user() { busctl call org.freedesktop.Accounts "$account" org.freedesktop.Accounts.User "$@"; }

      set_user SetEmail s "$email"

      # Picture, the first avatar found:
      # 1. the avatar link of the address's WebFinger profile (https://<domain>/.well-known/webfinger)
      # 2. Libravatar: the domain's own avatar server (DNS: _avatars-sec._tcp.<domain>, HTTPS), else libravatar.org
      #    (itself falling back to Gravatar). Asked for no default image (d=404): none when there's no avatar.
      # Retries until the network is up (any error, a minute at most), so a missing WebFinger only delays briefly.
      curl() { command curl -fsSL --retry 5 --retry-all-errors --retry-max-time 60 "$@"; }
      fetch() { curl -o "$RUNTIME_DIRECTORY/avatar" "$1" 2>/dev/null; }
      avatar=""
      if finger=$(curl --get --data-urlencode "resource=acct:$email" "https://$domain/.well-known/webfinger"); then
        avatar=$(jq -r '[.links[]? | select(.rel == "http://webfinger.net/rel/avatar")][0].href // empty' <<<"$finger")
      fi
      if [ -n "$avatar" ] && fetch "$avatar"; then
        echo "Avatar: WebFinger ($avatar)"
      else
        hash=$(printf %s "''${email,,}" | sha256sum | cut -d' ' -f1)
        # Lowest priority first, then highest weight: "<priority> <weight> <port> <host>."
        if srv=$(dig +short SRV "_avatars-sec._tcp.$domain" | sort -k1,1n -k2,2nr | head -n 1) && [ -n "$srv" ]; then
          read -r _ _ port host <<<"$srv"
          server="https://''${host%.}$([ "$port" = 443 ] || echo ":$port")"
        else
          server=https://seccdn.libravatar.org
        fi
        if fetch "$server/avatar/$hash?s=512&d=404"; then
          echo "Avatar: Libravatar ($server)"
        else
          echo "No avatar for $email"
          exit 0
        fi
      fi
      set_user SetIconFile s "$RUNTIME_DIRECTORY/avatar" # Copied to /var/lib/AccountsService/icons/<user>

      # ~/me.<ext> (ext of its image type: me.jpeg, me.png...): a link to that copy, for the user's own use. Previous
      # links to it (another type) are replaced; a file of the user's own isn't.
      icon=/var/lib/AccountsService/icons/$user
      home=$(getent passwd "$user" | cut -d: -f6)
      ext=$(file --brief --extension "$icon" | cut -d/ -f1)
      [ "$ext" != "???" ] || ext=img
      for old in "$home"/me.*; do
        if [ -L "$old" ] && [ "$(readlink "$old")" = "$icon" ] && [ "$old" != "$home/me.$ext" ]; then rm "$old"; fi
      done
      if [ -e "$home/me.$ext" ] && [ ! -L "$home/me.$ext" ]; then
        echo "$home/me.$ext exists and isn't a link: left as is"
      else
        ln -sfn "$icon" "$home/me.$ext"
        chown -h "$user:" "$home/me.$ext"
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
          description = "The user's email (AccountsService), its picture (WebFinger, Libravatar) and OpenPGP key (WKD, DANE).";
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
