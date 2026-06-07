{ home-manager, ... }:

{
  imports = [ home-manager.nixosModules.home-manager ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupCommand = "f=$1; mv -- \"$f\" \"$f.$(date +%Y%m%dT%H%M%S).bak\"";
  home-manager.sharedModules = [
    {
      programs.home-manager.enable = true;
      xdg.enable = true;
    }
    (import ../../../modules/home/environment)
    (import ../../../modules/home/programs/direnv)
    (import ../../../modules/home/programs/htop)
    (import ../../../modules/home/programs/ssh)
    (import ../../../modules/home/programs/starship)
    (import ../../../modules/home/programs/git)
    (import ../../../modules/home/programs/gpg)
    (import ../../../modules/home/programs/vim)
    (import ../../../modules/home/programs/zsh)
    (import ../../../modules/home/xdg)
  ];
}
