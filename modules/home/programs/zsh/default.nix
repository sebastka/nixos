{ config, lib, ... }:

{
  home.activation.createZshDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.xdg.cacheHome}/zsh
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
      size = 10000;
      ignoreDups = true;
      share = true;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };
}
