{ config, ... }:

{
  # Home-manager modules that support it (dircolors, npm, readline, kubecolor...) write their files
  # to XDG directories. Only affects modules enabled through home-manager.
  home.preferXdgDirectories = true;

  # Redirect GTK 2 reads to XDG. KDE still writes ~/.gtkrc-2.0 (unavoidable),
  # but GTK 2 apps read from the XDG path which includes it.
  home.sessionVariables.GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  xdg.configFile."gtk-2.0/gtkrc" = {
    force = true;
    text = ''
      include "${config.home.homeDirectory}/.gtkrc-2.0"
    '';
  };

  # Move GNUPGHOME out of ~/ into the XDG data directory.
  home.sessionVariables.GNUPGHOME = "${config.xdg.dataHome}/gnupg";

  # Claude Code (CLAUDE_CONFIG_DIR) and Codex (CODEX_HOME): set by their home-manager modules,
  # see modules/home/programs/coding-agents

  # Move .dotnet out of ~/ into the XDG data directory.
  home.sessionVariables.DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";

  # Ansible
  home.sessionVariables.ANSIBLE_HOME = "${config.xdg.dataHome}/ansible";
  home.sessionVariables.ANSIBLE_CONFIG = "${config.xdg.configHome}/ansible/ansible.cfg";
  home.sessionVariables.ANSIBLE_GALAXY_CACHE_DIR = "${config.xdg.cacheHome}/ansible/galaxy";

  # kubectl
  home.sessionVariables.KUBECONFIG = "${config.xdg.configHome}/kube/config.yaml";
  home.sessionVariables.KUBERC = "${config.xdg.configHome}/kube/rc.yaml";
  home.sessionVariables.KUBECACHEDIR = "${config.xdg.cacheHome}/kube";
  # talosctl
  home.sessionVariables.TALOSCONFIG = "${config.xdg.configHome}/talos/config.yaml";

  # AWS CLI
  home.sessionVariables.AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
  home.sessionVariables.AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";

  # Docker CLI: config.json (registry logins) instead of ~/.docker
  home.sessionVariables.DOCKER_CONFIG = "${config.xdg.configHome}/docker";

  # VS Code: only its user data follows XDG (~/.config/Code). The rest can't move (yet), checked in VS Code 1.119:
  # - ~/.vscode/extensions: home-manager links the extensions there (programs.vscode, by product.json's
  #   dataFolderName), so VS Code would stop finding them.
  # home.sessionVariables.VSCODE_EXTENSIONS = "${config.xdg.dataHome}/vscode/extensions";
  # - ~/.vscode-shared: only the --shared-data-dir flag moves it, no variable (it would need a wrapped launcher).
  # - ~/.vscode/argv.json and ~/.vscode/cli: only VSCODE_PORTABLE moves them, but it moves everything, the user data
  #   too: VS Code would then ignore ~/.config/Code, where home-manager writes settings.json and keybindings.json.
  # home.sessionVariables.VSCODE_PORTABLE = "${config.xdg.dataHome}/vscode";

  # wget: its HSTS database instead of ~/.wget-hsts (no env variable for it: set through wgetrc)
  home.sessionVariables.WGETRC = "${config.xdg.configHome}/wget/wgetrc";
  xdg.configFile."wget/wgetrc".text = ''
    hsts-file = ${config.xdg.cacheHome}/wget-hsts
  '';

  # Languages, mostly used from project devShells (direnv): their caches and tools out of ~/
  # Go: modules cache and `go install` binaries instead of ~/go
  home.sessionVariables.GOPATH = "${config.xdg.dataHome}/go";

  # Rust: toolchains and crates instead of ~/.rustup, ~/.cargo
  home.sessionVariables.RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
  home.sessionVariables.CARGO_HOME = "${config.xdg.dataHome}/cargo";

  # npm: user config, cache and logs instead of ~/.npmrc, ~/.npm
  home.sessionVariables.NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
  home.sessionVariables.NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
  home.sessionVariables.NPM_CONFIG_LOGS_DIR = "${config.xdg.stateHome}/npm/logs";

  # Node.js REPL history instead of ~/.node_repl_history
  home.sessionVariables.NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";

  # Python 3.13+ REPL history instead of ~/.python_history
  home.sessionVariables.PYTHON_HISTORY = "${config.xdg.stateHome}/python_history";

  # Sigstore (cosign): TUF trust data instead of ~/.sigstore
  home.sessionVariables.TUF_ROOT = "${config.xdg.dataHome}/sigstore/root";

  # Delete cache files unused for 30 days (systemd-tmpfiles-clean.timer, daily): caches survive reboots,
  # without growing forever. Not a tmpfs: npm, browsers, Nix... caches are several GB, and would start cold.
  systemd.user.tmpfiles.rules = [ "e ${config.xdg.cacheHome} - - - 30d" ];
}
