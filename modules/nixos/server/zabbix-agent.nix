{ config, pkgs, ... }:

# Zabbix agent, monitored by the Zabbix server in the cluster (from the former Ansible role). Servers only.
# The classic agent: the NixOS module runs zabbix_agentd (Debian had agent 2, its built-in plugins aren't used).
# 7.0 LTS like Debian 13 (pkgs.zabbix is 6.0).
let
  lan = import ../../../hosts/helios/lan.nix;
  zabbixServer = lan.vips.zabbixServer; # Zabbix server VIP: the active checks' target
  # Passive checks come from the server's node instead (Cilium masquerades its pods' connections to their node's IP),
  # so its VIP and every node: allowed in the host's firewall too (hosts/helios/firewall.nix)
  passiveSources = [ zabbixServer ] ++ map (host: lan.hosts.${host}.ip) lan.clusterNodes;
in
{
  services.zabbixAgent = {
    enable = true;
    package = pkgs.zabbix70.agent;
    server = builtins.concatStringsSep "," passiveSources; # Passive checks
    # Logs to the journal (LogType=console, set by the module; Ansible had system, i.e. syslog)
    settings = {
      ServerActive = zabbixServer; # Active checks
      Hostname = config.networking.fqdnOrHostName; # e.g. hermes.home.karlsen.fr, as in Zabbix
      LogRemoteCommands = 1; # system.run (denied by default); agent 2: Plugins.SystemRun.LogRemoteCommands
    };
  };

  # Once the network is up: started earlier, its active checks fail ("Network is unreachable") until their next retry
  systemd.services.zabbix-agent = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}
