{ config, ... }:

{
  # Redirect GTK 2 reads to XDG. KDE still writes ~/.gtkrc-2.0 (unavoidable),
  # but GTK 2 apps read from the XDG path which includes it.
  home.sessionVariables.GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  xdg.configFile."gtk-2.0/gtkrc" = {
    force = true;
    text = ''
      include "${config.home.homeDirectory}/.gtkrc-2.0"
    '';
  };

  # Move GNUPGHOME out of ~/ into the XDG data directory.
  home.sessionVariables.GNUPGHOME = "${config.xdg.dataHome}/gnupg";

  # Move Claude Code config out of ~/.claude into the XDG config directory.
  home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";

  # Move .dotnet out of ~/ into the XDG data directory.
  home.sessionVariables.DOTNET_CLI_HOME = "${config.xdg.dataHome}/dotnet";

  # Ansible
  home.sessionVariables.ANSIBLE_HOME = "${config.xdg.dataHome}/ansible";
  home.sessionVariables.ANSIBLE_CONFIG = "${config.xdg.configHome}/ansible/ansible.cfg";
  home.sessionVariables.ANSIBLE_GALAXY_CACHE_DIR = "${config.xdg.cacheHome}/ansible/galaxy";

  # kubectl
  home.sessionVariables.KUBECONFIG = "${config.xdg.configHome}/kube/config";
  home.sessionVariables.KUBECTL_KUBERC = "${config.xdg.configHome}/kube/kuberc";
  home.sessionVariables.KUBECACHEDIR = "${config.xdg.cacheHome}/kube";
  # talosctl
  home.sessionVariables.TALOSCONFIG = "${config.xdg.configHome}/talos/config.yaml";

  # AWS CLI
  home.sessionVariables.AWS_CONFIG_FILE = "${config.xdg.configHome}/aws/config";
  home.sessionVariables.AWS_SHARED_CREDENTIALS_FILE = "${config.xdg.configHome}/aws/credentials";
}
