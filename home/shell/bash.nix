{
  config,
  ...
}:
{
  programs.bash.enable = true;
  home.sessionVariables.HISTCONTROL = "ignoreboth";

  programs.starship.enable = true;
  programs.starship.enableBashIntegration = true;

  home.sessionVariables.HISTFILE = "${config.xdg.stateHome}/bash/history";
}
