{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      color.ui = true;
      init.defaultBranch = "master";
      pull.rebase = false;
      push.default = "upstream";
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };
}
