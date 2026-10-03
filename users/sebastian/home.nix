{ ... }:

{
  # GnuPG keys live on Yubikeys (private primary keys are offline).
  # On a new machine, run `gpg --card-status` once per Yubikey to link the subkeys to the cards.
  programs.gpg = {
    settings.default-key = "0B25B26C537B40B5B208F3A6C74C02E66D0CBECF";
    publicKeys = [
      { source = ./keys/private.asc; trust = 5; } # sebastian@karlsen.fr, Yubikey ...40146785
      { source = ./keys/inboxcom.asc; trust = 5; } # sebastian@corp.inbox.com, Yubikey ...40146786
    ];
  };

  programs.git = {
    signing = {
      format = "openpgp";
      key = "0B25B26C537B40B5B208F3A6C74C02E66D0CBECF";
      signByDefault = true;
    };
    settings = {
      user.name = "Sebastian Karlsen";
      user.email = "sebastian@karlsen.fr";
    };

    # Work repositories: inboxcom identity, signing key and SSH key for GitHub
    # (same host as personal repos, GitHub picks the account from the SSH key).
    includes = [
      {
        condition = "gitdir:~/Dev/Work/";
        contents = {
          user.email = "sebastian@corp.inbox.com";
          user.signingKey = "6908E0776A37F2BAAC4E192FE361F48DB812586F";
          core.sshCommand = "ssh -i ~/.ssh/key/inboxcom.id_ed25519_sk_rk";
        };
      }
    ];
  };

  home.stateVersion = "26.05";
}
