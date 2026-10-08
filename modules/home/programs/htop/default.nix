{ config, ... }:

{
  # The system's settings (modules/nixos/common/htop.nix), the same as root's (sudo htop). A link to /etc, not to the
  # store: htop doesn't overwrite it (read-only), and it follows the system's changes.
  xdg.configFile."htop/htoprc".source = config.lib.file.mkOutOfStoreSymlink "/etc/htoprc";
}
