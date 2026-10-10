{
  config,
  pkgs,
  pkgs-unstable,
  ...
}:

{
  # Node.js (the current LTS) and npm, its package manager: the default everywhere. Projects pinning another version
  # (.nvmrc, .node-version) get theirs from fnm (below).
  programs.npm = {
    enable = true;
    package = pkgs-unstable.nodejs_26;
    # `npm install -g` into ~/.local/share/npm, not the read-only Nix store (its commands: home.sessionPath below).
    # The npmrc is generated: settings go here, not through `npm config set`.
    settings.prefix = "${config.xdg.dataHome}/npm";
  };
  home.sessionPath = [ "${config.xdg.dataHome}/npm/bin" ];

  home.packages = [
    # The other package managers, for projects using them (their lockfile: pnpm-lock.yaml, yarn.lock). Node.js no
    # longer ships corepack, which used to provide them.
    pkgs-unstable.pnpm
    pkgs-unstable.yarn-berry # Yarn 2+ (`yarn`)

    # Node.js versions per project: fnm installs the one in .nvmrc or .node-version (in ~/.local/share/fnm, from
    # nodejs.org: their binaries run through nix-ld, modules/nixos/common) and uses it on entering the project
    pkgs.fnm
  ];

  # Yarn's global cache instead of ~/.yarn
  home.sessionVariables.YARN_GLOBAL_FOLDER = "${config.xdg.dataHome}/yarn";

  # On cd into a project with .nvmrc or .node-version: its version (asks to install it the first time). Elsewhere,
  # the Node.js above.
  programs.zsh.initContent = ''
    eval "$(${pkgs.fnm}/bin/fnm env --use-on-cd --shell zsh)"
  '';
}
