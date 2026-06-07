{
  pkgs,
  lib,
  config,
  self,
  sops-nix,
  ...
}:

{
  imports = [
    ../home-manager
    sops-nix.nixosModules.sops
  ];

  sops.defaultSopsFile = "${self}/secrets/secrets.yaml";
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
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

  # Latest upstream kernel for best hardware support and driver coverage on laptops.
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Oslo";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nb_NO.UTF-8";
    LC_IDENTIFICATION = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_NAME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_TELEPHONE = "nb_NO.UTF-8";
    LC_TIME = "nb_NO.UTF-8";
  };

  networking.domain = "home.karlsen.fr";
  networking.nftables.enable = true;

  programs.zsh.enable = true;

  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
    PAGER = "less";
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "EDITOR VISUAL PAGER"
  '';

  environment.systemPackages = with pkgs; [
    wget
    git
    htop
    duf
    lm_sensors
    nixfmt
    jq
    yq-go
    dig
  ];

  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      LoginGraceTime = 5;
      MaxAuthTries = 3;
    };
    extraConfig = ''
      AllowTcpForwarding no
      AllowAgentForwarding no
      ChannelTimeout *=2h
      UnusedConnectionTimeout 1m
      PrintMotd no

      # SSH CA: uncomment once CA infrastructure is in place
      # TrustedUserCAKeys /etc/ssh/user_ca_key.pub
      # RevokedKeys /etc/ssh/revoked_keys
      # HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
      # HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
    '';
  };
}
