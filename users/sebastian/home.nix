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
}
