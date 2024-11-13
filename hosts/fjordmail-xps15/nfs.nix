{
  pkgs, 
  ...
}: {

  environment.systemPackages = with pkgs; [ nfs-utils ];

  # NFS
  # file.atlas.home.karlsen.fr:/mnt/nfs/Documents     /home/sebastian/nfs/Documents/ nfs defaults,noauto,user,nfsvers=4,soft 0 0
  # file.atlas.home.karlsen.fr:/mnt/nfs/Downloads     /home/sebastian/nfs/Downloads/ nfs defaults,noauto,user,nfsvers=4,soft 0 0
  # file.atlas.home.karlsen.fr:/mnt/nfs/Music     /home/sebastian/nfs/Music/ nfs defaults,noauto,user,nfsvers=4,soft 0 0
  # file.atlas.home.karlsen.fr:/mnt/nfs/Pictures     /home/sebastian/nfs/Pictures/ nfs defaults,noauto,user,nfsvers=4,soft 0 0
  # file.atlas.home.karlsen.fr:/mnt/nfs/Videos     /home/sebastian/nfs/Videos/ nfs defaults,noauto,user,nfsvers=4,soft 0 0
  # torrent.atlas.home.karlsen.fr:/mnt/nfs/data    /home/sebastian/nfs/Torrent/ nfs defaults,noauto,user,nfsvers=4,ro 0 0
  #fileSystems."/home/sebastian/nfs/Documents" = { device = "file.atlas.home.karlsen.fr:/mnt/nfs/Documents"; fsType = "nfs"; options = [ "x-systemd.automount" "x-systemd.idle-timeout=600" "noauto" "user" "nfsvers=4.2" "soft" ]; };
  #fileSystems."/home/sebastian/nfs/Downloads" = { device = "file.atlas.home.karlsen.fr:/mnt/nfs/Downloads"; fsType = "nfs"; options = [ "defaults" "noauto" "user" "nfsvers=4.2" "soft" ]; };
  #fileSystems."/home/sebastian/nfs/Music" = { device = "file.atlas.home.karlsen.fr:/mnt/nfs/Music"; fsType = "nfs"; options = [ "defaults" "noauto" "user" "nfsvers=4.2" "soft" ]; };
  #fileSystems."/home/sebastian/nfs/Pictures" = { device = "file.atlas.home.karlsen.fr:/mnt/nfs/Pictures"; fsType = "nfs"; options = [ "defaults" "noauto" "user" "nfsvers=4.2" "soft" ]; };
  #fileSystems."/home/sebastian/nfs/Videos" = { device = "file.atlas.home.karlsen.fr:/mnt/nfs/Videos"; fsType = "nfs"; options = [ "defaults" "noauto" "user" "nfsvers=4.2" "soft" ]; };
  #fileSystems."/home/sebastian/nfs/Torrent" = { device = "torrent.atlas.home.karlsen.fr:/mnt/nfs/data"; fsType = "nfs"; options = [ "defaults" "noauto" "user" "nfsvers=4.2" "soft" "ro" ]; };

  # https://nixos.wiki/wiki/NFS
  # https://github.com/NixOS/nixpkgs/issues/76671
  services.rpcbind.enable = true; # needed for NFS
  boot.supportedFilesystems = [ "nfs" ];
  boot.initrd.kernelModules = [ "nfs" ];
  systemd.mounts = 
    let
      commonMountOptions = {
        type = "nfs";
        mountConfig = {
          Options = "noatime,user,nfsvers=4.2,soft";
        };
      };

    in

      [
        (commonMountOptions // { what = "file.atlas.home.karlsen.fr:/mnt/nfs/Documents"; where = "/home/sebastian/nfs/Documents"; })
        (commonMountOptions // { what = "file.atlas.home.karlsen.fr:/mnt/nfs/Downloads"; where = "/home/sebastian/nfs/Downloads"; })
        (commonMountOptions // { what = "file.atlas.home.karlsen.fr:/mnt/nfs/Music"; where = "/home/sebastian/nfs/Music"; })
        (commonMountOptions // { what = "file.atlas.home.karlsen.fr:/mnt/nfs/Pictures"; where = "/home/sebastian/nfs/Pictures"; })
        (commonMountOptions // { what = "file.atlas.home.karlsen.fr:/mnt/nfs/Videos"; where = "/home/sebastian/nfs/Videos"; })
        (commonMountOptions // { what = "torrent.atlas.home.karlsen.fr:/mnt/nfs/data"; where = "/home/sebastian/nfs/Torrent"; /*options = [ "ro" ];*/ })
      ];

  systemd.automounts =
    let
      commonAutoMountOptions = {
        wantedBy = [ "multi-user.target" ];
        automountConfig = {
          TimeoutIdleSec = "600";
        };
      };

    in

      [
        (commonAutoMountOptions // { where = "/home/sebastian/nfs/Documents"; })
        (commonAutoMountOptions // { where = "/home/sebastian/nfs/Downloads"; })
        (commonAutoMountOptions // { where = "/home/sebastian/nfs/Music"; })
        (commonAutoMountOptions // { where = "/home/sebastian/nfs/Pictures"; })
        (commonAutoMountOptions // { where = "/home/sebastian/nfs/Videos"; })
        (commonAutoMountOptions // { where = "/home/sebastian/nfs/Torrent"; })
      ];
}
