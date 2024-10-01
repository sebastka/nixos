{
  lib,
  config,
  ...
}: {
  # Set your time zone.
  time.timeZone = "Europe/Oslo";

  # Configure console keymap
  console.keyMap = "no";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "nb_NO.UTF-8";
    LC_IDENTIFICATION = "nb_NO.UTF-8";
    LC_MEASUREMENT = "nb_NO.UTF-8";
    LC_MONETARY = "nb_NO.UTF-8";
    LC_NAME = "nb_NO.UTF-8";
    LC_NUMERIC = "nb_NO.UTF-8";
    LC_PAPER = "nb_NO.UTF-8";
    LC_TELEPHONE = "nb_NO.UTF-8";
    LC_TIME = "nb_NO.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = lib.mkIf (config.services.xserver.enable == true) {
    layout = "no";
    variant = "nodeadkeys";
  };
}
