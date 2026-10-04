{ config, lib, ... }:

{
  home.activation.createZshDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.xdg.cacheHome}/zsh
  '';

  # One-time move of the history file from $XDG_DATA_HOME to $XDG_STATE_HOME (history is state).
  # Can be removed once every machine has been switched.
  home.activation.moveZshHistory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    old="${config.xdg.dataHome}/zsh/history"
    new="${config.xdg.stateHome}/zsh/history"
    if [ -f "$old" ] && [ ! -e "$new" ]; then
      run mkdir -p "$(dirname "$new")"
      run mv "$old" "$new"
    fi
  '';

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    completionInit = "autoload -U compinit && compinit -d ${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION";
    shellAliases = {
      ll = "ls -alhvN --group-directories-first";
      grep = "grep --color=auto";
      se = "sudoedit";
      sctl = "sudo systemctl";
      jctl = "sudo journalctl";
      k = "kubecolor";
      tf = "tofu";
    };
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 100000; # Lines in memory; also saved to the file (`save` defaults to `size`)
      path = "${config.xdg.stateHome}/zsh/history";
      share = true; # Share history between open shells, written as soon as a command runs
      extended = true; # Save timestamps (implied by `share`, explicit here): `history -i` shows them
      ignoreDups = true; # Skip a command identical to the previous one
      expireDuplicatesFirst = true; # When the history is full, drop duplicates before unique commands
      ignoreSpace = true; # Commands starting with a space are not saved (e.g. with a secret inline)
    };
  };
}
