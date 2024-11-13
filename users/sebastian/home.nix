{
  config,
  ...
}: {
  # Home Manager Config

  imports = [
    ../../home/core.nix
    ../../home/shell
    ../../home/programs
    ../../home/tailscale.nix
    ../../home/desktop
  ];

  # nfs mounts
  # https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files
  # Why don’t you use an automount unit? An automount unit only mount the share when it is accessed - which is what your want - a user logged in before mounting the share.
  # systemd.user.mounts.Documents = {
  #   Unit = { Description = "Mount Documents"; After = [ "network-online.target" ]; Wants = [ "network-online.target" ]; };
  #   Automount = { Where = "${config.home.homeDirectory}/nfs/Documents"; };
  # };
  # systemd.user.mounts.Downloads = {
  #   Unit = { Description = "Mount Downloads"; After = [ "network-online.target" ]; Wants = [ "network-online.target" ]; };
  #   Automount = { Where = "${config.home.homeDirectory}/nfs/Downloads"; };
  # };
  # systemd.user.mounts.Music = {
  #   Unit = { Description = "Mount Music"; After = [ "network-online.target" ]; Wants = [ "network-online.target" ]; };
  #   Automount = { Where = "${config.home.homeDirectory}/nfs/Music"; };
  # };
  # systemd.user.mounts.Pictures = {
  #   Unit = { Description = "Mount Pictures"; After = [ "network-online.target" ]; Wants = [ "network-online.target" ]; };
  #   Automount = { Where = "${config.home.homeDirectory}/nfs/Pictures"; };
  # };
  # systemd.user.mounts.Videos = {
  #   Unit = { Description = "Mount Videos"; After = [ "network-online.target" ]; Wants = [ "network-online.target" ]; };
  #   Automount = { Where = "${config.home.homeDirectory}/nfs/Videos"; };
  # };
  # systemd.user.mounts.Torrents = {
  #   Unit = { Description = "Mount Torrents"; After = [ "network-online.target" ]; Wants = [ "network-online.target" ]; };
  #   Automount = { Where = "${config.home.homeDirectory}/nfs/Torrents"; };
  # };

  # GPG
  programs.gpg.settings.default-key = "94863C7F986D65E8";

  # Git
  programs.git.userName = "Sebastian Karlsen";
  programs.git.userEmail = "sebastian@karlsen.fr";
  programs.git.signing = {
    key = config.programs.gpg.settings.default-key;
    signByDefault = true;
  };
  programs.git.extraConfig.url."git@github.com" = {
    insteadOf = "https://sebastka@github.com/";
  };

  # programs.thunderbird.enable = true;
  /*
  programs.thunderbird.profiles.settings = {};

  # programs.thunderbird.profiles.Private.extraConfig = {};
  programs.thunderbird.profiles.Private.isDefault = true;
  # programs.thunderbird.profiles.Private.settings = {};
  programs.thunderbird.profiles.Private.withExternalGnupg = true;

  # programs.thunderbird.profiles.Work.extraConfig = {};
  programs.thunderbird.profiles.Work.isDefault = false;
  # programs.thunderbird.profiles.Work.settings = {};
  # programs.thunderbird.profiles.Work.withExternalGnupg = true;

  # https://beb.ninja/post/email/
  accounts.email.accounts =
    let
      zoho_settings = {
        imap.host = "imappro.zoho.eu";
        imap.port = 993;
        imap.tls.enable = true;

        smtp.host = "smtppro.zoho.eu";
        smtp.port = 465;
        smtp.tls.enable = true;

        signature.showSignature = true;
        thunderbird.enable = true;
        thunderbird.profiles = [ "Work" ];
      };
    in
      {
        "sebastiancorpinboxcom" = zoho_settings // {
          primary = true;

          realName = "Sebastian Karlsen";
          address = "sebastian@corp.inbox.com";
          userName = "sebastian@corp.inbox.com";
          aliases = [ "sebastian.karlsen@corp.inbox.com" ];

          #gpg.key = config.programs.gpg.settings.default-key;
          #gpg.signByDefault = false;

          signature.text = 
            ''
            Sebastian Karlsen
            IT / Sysadmin / Ops
            (+47) 483 61 125
            Inbox.com
            '';
        };

        "postcorpinboxcom" = zoho_settings // {
          primary = false;

          realName = "Sebastian Karlsen";
          address = "post@corp.inbox.com";
          userName = "post@corp.inbox.com";
          aliases = [];

          #gpg.key = config.programs.gpg.settings.default-key;
          #gpg.signByDefault = false;

          signature.text = 
            ''
            Sebastian Karlsen
            IT / Sysadmin / Ops
            Inbox.com
            '';
        };

        "support3corpinboxcom" = zoho_settings // {
          primary = false;

          realName = "Sebastian Karlsen";
          address = "support3@corp.inbox.com";
          userName = "support3@corp.inbox.com";
          aliases = [];

          #gpg.key = config.programs.gpg.settings.default-key;
          #gpg.signByDefault = false;

          signature.text = 
            ''
            / Sebastian @ 3L Support
            '';
        };

        "support2corpinboxcom" = zoho_settings // {
          primary = false;

          realName = "Sebastian Karlsen";
          address = "support2@corp.inbox.com";
          userName = "support2@corp.inbox.com";
          aliases = [];

          #gpg.key = config.programs.gpg.settings.default-key;
          #gpg.signByDefault = false;

          signature.text = 
            ''
            / Sebastian @ 2L Support
            '';
        };
      };
    */
}
