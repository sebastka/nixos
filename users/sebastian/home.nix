{ ... }:

{
  programs.gpg.settings.default-key = "94863C7F986D65E8";

  programs.git = {
    signing = {
      key = "94863C7F986D65E8";
      signByDefault = true;
    };
    settings = {
      user.name = "Sebastian Karlsen";
      user.email = "sebastian@karlsen.fr";
    };
  };

  home.stateVersion = "26.05";
}
