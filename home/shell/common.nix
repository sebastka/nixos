{
  home.sessionVariables.EDITOR = "vim";
  home.sessionVariables.VISUAL = "$EDITOR";
  home.sessionVariables.PAGER = "less";
  home.sessionVariables.SYSTEMD_EDITOR = "$PAGER";
  home.sessionVariables.SYSTEMD_PAGER = "$PAGER";

  home.shellAliases = {
    e = "$EDITOR";
    se = "sudoedit";

    m = "$PAGER";

    sctl = "sudo systemctl";
    ll = "ls -alhvN --group-directories-first";
  };
}
