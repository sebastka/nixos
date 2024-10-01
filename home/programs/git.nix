{
  programs.git.enable = true;

  programs.git.aliases.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";

  programs.git.extraConfig.color.ui = true;
  programs.git.extraConfig.core.whitespace = "trailing-space,space-before-tab";
  programs.git.extraConfig.apply.whitespace = "fix";
  programs.git.extraConfig.init.defaultBranch = "master";
  programs.git.extraConfig.pull.rebase = false;
  programs.git.extraConfig.push.default = "upstream";

}
