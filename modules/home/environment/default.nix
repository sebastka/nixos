{ config, ... }:

{
  # EDITOR, VISUAL, PAGER are set system-wide in modules/nixos/common
  # so they are available to all processes including those run via sudo.
  # Not set, as their defaults already apply: FCEDIT, SYSTEMD_EDITOR (EDITOR), SYSTEMD_PAGER (PAGER),
  # GCC_COLORS (GCC's default colors), LS_COLORS (ls' built-in colors), CLICOLOR (BSD ls only). Never TERM:
  # forcing it breaks terminals that announce better capabilities.

  # make: one job per CPU (evaluated by the shell at login, so right on every host)
  home.sessionVariables.MAKEFLAGS = "-j$(nproc)";
}
