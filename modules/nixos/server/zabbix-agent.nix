{
  config,
  lib,
  pkgs,
  ...
}:

# Zabbix agent, monitored by the Zabbix server in the cluster (from the former Ansible role). Servers only.
# The classic agent: the NixOS module runs zabbix_agentd (Debian had agent 2, its built-in plugins aren't used).
# 7.0 LTS like Debian 13 (pkgs.zabbix is 6.0).
let
  lan = import ../../../hosts/helios/lan.nix;
  zabbixServer = lan.vips.zabbixServer; # Zabbix server VIP: the active checks' target
in
{
  # Where the passive checks come from, also for the host's firewall (hosts/<host>/firewall.nix). A list: a host adds
  # its own (hosts/file: inside the cluster, the server's pod connects with its pod address).
  options.services.zabbixAgent.passiveSources = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = "Addresses or CIDRs allowed to run passive checks (the agent's Server).";
  };

  config = {
    # From outside the cluster, the server's node (Cilium masquerades its pods' connections to their node's IP): its
    # VIP and every node (allowed in hosts/helios/firewall.nix too)
    services.zabbixAgent.passiveSources = [
      zabbixServer
    ]
    ++ map (host: lan.hosts.${host}.ip) lan.clusterNodes;

    services.zabbixAgent = {
      enable = true;
      package = pkgs.zabbix70.agent;
      server = builtins.concatStringsSep "," config.services.zabbixAgent.passiveSources; # Passive checks
      # Logs to the journal (LogType=console, set by the module; Ansible had system, i.e. syslog)
      settings = {
        ServerActive = zabbixServer; # Active checks
        Hostname = config.networking.fqdnOrHostName; # e.g. hermes.home.karlsen.fr, as in Zabbix
        LogRemoteCommands = 1; # system.run (denied by default); agent 2: Plugins.SystemRun.LogRemoteCommands
      };
    };

    # Once the network is up: started earlier, its active checks fail ("Network is unreachable") until their next
    # retry
    systemd.services.zabbix-agent = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };
  };
}
