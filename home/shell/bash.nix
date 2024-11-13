{
  config,
  ...
}:
{
  programs.bash.enable = true;
  home.sessionVariables.HISTFILE = "${config.xdg.stateHome}/bash/history";

  #home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";
  programs.starship.enable = true;
  programs.starship.enableBashIntegration = true;
  programs.starship.settings.add_newline = false;
  programs.starship.settings.line_break.disabled = true;
  programs.starship.settings.aws.disabled = true;
}
