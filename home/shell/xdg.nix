{
  config,
  ...
}:
{
  xdg.enable = true;
  xdg.cacheHome = config.home.homeDirectory + "/.local/cache";

  xdg.mimeApps.enable = true;
  xdg.configFile."mimeapps.list".force = true;
  #xdg.mimeApps.defaultApplications = {};

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;
  xdg.userDirs.extraConfig.XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
}
