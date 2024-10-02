{
  config,
  ...
}:
{
  programs.bash.enable = true;

  programs.starship.enable = true;
  programs.starship.enableBashIntegration = true;

  home.sessionVariables.HISTFILE = "${config.xdg.stateHome}/bash/history";
}
