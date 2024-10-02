{
  home.shellAliases = {
    ll = "ls -alhvN --group-directories-first";

    e = "$EDITOR";
    se = "sudoedit";

    m = "$PAGER";

    sctl = "sudo systemctl";
    jctl = "sudo journalctl --boot --follow --unit";

    # git
    g = "git";
    ga = "git add";
    gc = "git commit";
  };
}
