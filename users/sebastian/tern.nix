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
  profiles = [
    "private"
    "inboxcom-test"
  ];

  # Same settings for both profiles
  profile = ''
    display_name = "Sebastian Karlsen"
    archive = "Archive/{year}"

    [store]
    compress = true        # zstd-compress stored messages
    compression_level = 3
  '';

  nixosConfig = config;
in
{
  config = lib.mkIf nixosConfig.services.xserver.enable {
    # Account files and signatures are secrets, names included: secrets/tern.sops.yaml holds
    #   files: [ { path: <relative to ~/.config/tern>, content: <file content> } ]
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

        xdg.configFile = {
          # Tern never writes its configuration: read-only files are fine
          "tern/tern.toml".text = ''
            default_profile = "private"
            ask_on_startup = true

            [ui]
            threaded = false
            prefer_plain_text = false

            [gpg]
            program = "gpg"
            wkd_lookup = true

            [memory]
            message_cache_mb = 64      # rendered messages kept in memory, attachments included
            spare_renderer = true      # keep a spare Chromium renderer ready (faster, ~30 MiB more)
          '';
        }
        // lib.genAttrs (map (p: "tern/profiles/${p}/profile.toml") profiles) (_: {
          text = profile;
        });

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
