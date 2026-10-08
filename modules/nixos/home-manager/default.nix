{ home-manager, pkgs, ... }:

{
  imports = [ home-manager.nixosModules.home-manager ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # A file in the way of a link is moved aside, to <file>.<date>.bak. A script: home-manager runs the command
  # unquoted (`$command "$file"`), so shell code in it (f=$1; ...) would be word-split, and fail.
  home-manager.backupCommand = pkgs.writeShellScript "home-manager-backup" ''
    mv -- "$1" "$1.$(date +%Y%m%dT%H%M%S).bak"
  '';
  home-manager.sharedModules = [
    {
      programs.home-manager.enable = true;
      xdg.enable = true;
    }
    (import ../../../modules/home/environment)
    (import ../../../modules/home/programs/bw)
    (import ../../../modules/home/programs/bws)
    (import ../../../modules/home/programs/direnv)
    (import ../../../modules/home/programs/htop)
    (import ../../../modules/home/programs/neovim)
    (import ../../../modules/home/programs/readline)
    (import ../../../modules/home/programs/ssh)
    (import ../../../modules/home/programs/starship)
    (import ../../../modules/home/programs/git)
    (import ../../../modules/home/programs/gpg)
    (import ../../../modules/home/programs/vim)
    (import ../../../modules/home/programs/web-apps)
    (import ../../../modules/home/programs/zsh)
    (import ../../../modules/home/xdg)
  ];
}
