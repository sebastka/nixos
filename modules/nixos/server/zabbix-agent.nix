{ config, pkgs, ... }:

# Zabbix agent, monitored by the Zabbix server in the cluster (from the former Ansible role). Servers only.
# The classic agent: the NixOS module runs zabbix_agentd (Debian had agent 2, its built-in plugins aren't used).
# 7.0 LTS like Debian 13 (pkgs.zabbix is 6.0).
let
  zabbixServer = "192.168.2.12"; # Zabbix server VIP, also allowed in ./firewall.nix
in
{
  services.zabbixAgent = {
    enable = true;
    package = pkgs.zabbix70.agent;
    server = zabbixServer; # Passive checks
    # Logs to the journal (LogType=console, set by the module; Ansible had system, i.e. syslog)
    settings = {
      ServerActive = zabbixServer; # Active checks
      Hostname = config.networking.fqdnOrHostName; # e.g. hermes.home.karlsen.fr, as in Zabbix
      LogRemoteCommands = 1; # system.run (denied by default); agent 2: Plugins.SystemRun.LogRemoteCommands
    };
  };
}
