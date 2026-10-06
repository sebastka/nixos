# Tern mail client (https://github.com/sebastka/tern) for sebastian.
# NixOS module, applied on desktops (services.xserver.enable): they must be recipients of
# secrets/tern.sops.yaml (.sops.yaml).
{
  config,
  lib,
  pkgs,
  self,
  ...
}:

let
  user = "sebastian";
  nixosConfig = config;
in
{
  config = lib.mkIf nixosConfig.services.xserver.enable {
    # Profiles (found by Tern from their directories), account files and signatures are secrets, names
    # included: secrets/tern.sops.yaml holds
    #   files: [ { path: <relative to ~/.config/tern>, content: <file content> } ]
    # e.g. profiles/<profile>/profile.toml and profiles/<profile>/accounts/<id>.toml,
    # with both values encrypted. The host decrypts the whole file (readable by the user only).
    sops.secrets.tern-config = {
      sopsFile = "${self}/secrets/tern.sops.yaml";
      key = ""; # Whole file
      owner = user;
    };

    home-manager.users.${user} =
      { config, lib, ... }: # home-manager's lib (lib.hm)
      {
        home.packages = [
          self.inputs.tern.packages.${pkgs.stdenv.hostPlatform.system}.default
          pkgs.libsecret # secret-tool: store the account passwords (password.keyring) in the keyring
        ];

        # Tern never writes its configuration: read-only files are fine
        xdg.configFile."tern/tern.toml".text = ''
          default_profile = "private"
          ask_on_startup = true
          sent_folder = "Sent"

          [ui]
          threaded = false
          prefer_plain_text = false

          [ui.message_list]
          # Left to right: flag, subject, from, to, correspondent, date, attachment, size.
          # "correspondent" is From, or To in Sent and Drafts folders.
          columns = ["flag", "subject", "from", "to", "date", "attachment", "size"]   # not empty, no duplicates
          sort_by = "date"       # any of the above; it doesn't have to be shown
          sort_order = "asc"     # asc | desc
          group_by_date = true

          [gpg]
          program = "gpg"
          wkd_lookup = true

          [avatars]
          lookup = "trusted"
          sources = ["webfinger", "libravatar"]

          [compose]
          format = "plain"   # default editor: plain | markdown | html (no signature here)

          [memory]
          message_cache_mb = 64      # rendered messages kept in memory, attachments included
          spare_renderer = true      # keep a spare Chromium renderer ready (faster, ~30 MiB more)

          [notifications]
          enabled = true
          sound = true
          folders = ["*"]
          # exclude_folders = []
        '';

        # Write the secret files into ~/.config/tern (mode 600) when switching. The paths written are
        # recorded, so files removed from the secret are deleted at the next switch.
        home.activation.ternSecretFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          src="${nixosConfig.sops.secrets.tern-config.path}"
          dir="${config.xdg.configHome}/tern"
          list="${config.xdg.stateHome}/tern/secret-files"
          if [ ! -r "$src" ]; then
            echo "tern: $src not available (is this host a recipient of secrets/tern.sops.yaml?), skipping" >&2
          else
            if [ -f "$list" ]; then
              while IFS= read -r path; do run rm -f -- "$dir/$path"; done < "$list"
            fi
            json="$(${lib.getExe pkgs.yq-go} -o=json . "$src")"
            count="$(${lib.getExe pkgs.jq} '.files | length' <<< "$json")"
            paths=()
            for ((i = 0; i < count; i++)); do
              path="$(${lib.getExe pkgs.jq} -r ".files[$i].path" <<< "$json")"
              case "/$path/" in
                //* | */../*) echo "tern: refusing path: $path" >&2; exit 1 ;;
              esac
              # jq -j: exact content, no added newline
              run install -D -m 600 <(${lib.getExe pkgs.jq} -j ".files[$i].content" <<< "$json") "$dir/$path"
              paths+=("$path")
            done
            run install -D -m 600 <(printf '%s\n' "''${paths[@]}") "$list"
          fi
        '';
      };
  };
}
