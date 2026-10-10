{
  pkgs,
  pkgs-unstable,
  lib,
  config,
  self,
  sops-nix,
  ...
}:

{
  imports = [
    ../home-manager
    ./htop.nix
    ./openssh.nix
    ./user-email.nix
    sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFile = "${self}/secrets/common.sops.yaml";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  users.mutableUsers = false;
  sops.secrets."root-password".neededForUsers = true;
  users.users.root.hashedPasswordFile = config.sops.secrets."root-password".path;

  nixpkgs.config.allowUnfree = true;
  nix.settings.use-xdg-base-directories = true;
  nix.settings.experimental-features = [
    "nix-command" # Enable the new `nix` CLI subcommands (nix build, nix run, nix shell, etc.)
    "flakes" # Enable flakes for pinned, reproducible dependency management
    # "auto-allocate-uids"      # Automatically pick UIDs for builds instead of creating nixbld* accounts
    # "blake3-hashes"           # Enable support for BLAKE3 hashes in the store
    # "ca-derivations"          # Content-addressed derivations: skip rebuilds when output is identical
    # "cgroups"                 # Execute builds inside cgroups for better resource isolation
    # "configurable-impure-env" # Allow setting the impure-env config option per-build
    # "daemon-trust-override"   # Let clients override their trust level with nix-daemon
    # "dynamic-derivations"     # Build .drv files and depend on derivation outputs at eval time
    # "fetch-closure"           # Enable fetchClosure built-in to copy store paths from a binary cache
    # "fetch-tree"              # Enable fetchTree built-in for fetching arbitrary source trees
    # "git-hashing"             # Store objects hashed with Git's SHA1 algorithm
    # "impure-derivations"      # Allow __impure derivations whose outputs are non-deterministic
    # "local-overlay-store"     # Overlay a writable layer on top of a read-only local store
    # "mounted-ssh-store"       # Access a remote store mounted locally via SSH
    # "no-url-literals"         # Forbid unquoted URLs in Nix expressions (stricter purity)
    # "parse-toml-timestamps"   # Parse ISO-8601 timestamps in builtins.fromTOML
    # "pipe-operators"          # Add |> and <| pipe operators to the Nix language
    # "read-only-local-store"   # Allow opening the local store in read-only mode
    # "recursive-nix"           # Let build sandboxes call Nix themselves (recursive builds)
    # "verified-fetches"        # Verify GPG signatures on commits fetched via fetchGit
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  boot.kernelPackages = lib.mkOverride 1001 pkgs.linuxPackages_latest; # Below mkDefault, so hardware modules (RPi, Asahi) pick their own kernel
  boot.tmp.useTmpfs = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Oslo";

  # Norwegian keyboard by default (also the LUKS passphrase prompt); a host with another keyboard sets its own
  # (zeus). The graphical layout: modules/nixos/desktop.
  console.keyMap = lib.mkDefault "no";

  # English messages, Norwegian formats, except dates and sorting
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_DK.UTF-8"; # English names, ISO dates (2026-10-05), 24-hour clock
    LC_COLLATE = "C.UTF-8"; # Byte order: dotfiles, then uppercase before lowercase (ls, sort, globs)
    LC_ADDRESS = "nb_NO.UTF-8";
    LC_IDENTIFICATION = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_NAME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_TELEPHONE = "nb_NO.UTF-8";
  };

  networking.domain = "home.karlsen.fr";
  networking.nftables.enable = true;

  programs.zsh.enable = true;

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "EDITOR VISUAL PAGER"
  '';

  environment.systemPackages = with pkgs; [
    wget
    git
    duf
    lm_sensors
    nixfmt
    jq
    yq-go
    dig
    gettext # GNU envsubst
    pkgs-unstable.python3 # Bare interpreter: scripts and REPL (projects: uv)
    pkgs-unstable.uv # Python projects (.venv, uv.lock): the same, recent version on every host (its lock format)
  ];

  # uv builds venvs on its own Python builds (downloaded to ~/.local/share/uv/python), never on the Nix one: wheels
  # with native code (numpy...) need libraries (libstdc++...) that the Nix Python can't find, while uv's Python runs
  # through nix-ld (below), which provides them.
  environment.variables.UV_PYTHON_PREFERENCE = "only-managed";

  # Dynamically-linked binaries from outside nixpkgs: VS Code extensions' bundled binaries, uv's Python (and its
  # wheels), bw (pkgs/bitwarden-cli)...
  programs.nix-ld.enable = true;
  # programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ]; # If one misses a library

  programs.screen.enable = true; # Not just the package: also its PAM service, for locking (C-a x)
}
