{
  config,
  ...
}: {
  home.sessionVariables = {
    # Default utils
    EDITOR = "vim";
    VISUAL = "$EDITOR";
    PAGER = "less";

    # Systemd
    SYSTEMD_EDITOR = "$PAGER";
    SYSTEMD_PAGER = "$PAGER";

    # Ansible
    ANSIBLE_HOME = "${config.xdg.configHome}/ansible";
    ANSIBLE_CONFIG = "${config.xdg.configHome}/ansible.cfg";
    ANSIBLE_GALAXY_CACHE_DIR = "${config.xdg.cacheHome}/ansible/galaxy_cache";

    # Xorg
    USERXSESSION = "${config.xdg.cacheHome}/X11/xsession";
    USERXSESSIONRC = "${config.xdg.cacheHome}/X11/xsessionrc";
    ALTUSERXSESSION = "${config.xdg.cacheHome}/X11/Xsession";
    ERRFILE = "${config.xdg.cacheHome}/X11/xsession-errors";

    # libx11
    XCOMPOSEFILE = "${config.xdg.configHome}/X11/xcompose";
    XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";

    # xorg-xauth
    # XAUTHORITY = "${config.xdg.cacheHome}/X11/Xauthority"; # Breaks xorg-auth

    # Shells
    HISTCONTROL = "ignoreboth";

    # Bash
    BASH_COMPLETION_USER_FILE = "${config.xdg.configHome}/bash-completion/bash_completion";
  };
}
