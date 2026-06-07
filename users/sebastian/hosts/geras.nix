{ config, lib, ... }:

{
  imports = [ ../../../modules/home/programs/ktailctl ];

  # SSH public key derived from the GPG authentication subkey (created 2026-06-06):
  #   Fingerprint: 6457 9413 2952 C8E2 8542  7A90 9E90 4396 E4F9 8B52
  #   Long ID:     9E904396E4F98B52
  #   Short ID:    E4F98B52
  home.file.".ssh/geras.pub".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILc+CN5HWAyK9Ciu3CgRZ4YYLvtU2NIRKJHhrYRDtt4j geras.home.karlsen.fr\n";

  # Register the GPG authentication subkey with gpg-agent so it is offered for SSH.
  home.activation.gpgSshControl = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    grep -qxF "86BD85347DF61C5CDCC0EB9FF04DDE1EA1FA3101" \
      "${config.xdg.dataHome}/gnupg/sshcontrol" 2>/dev/null \
      || echo "86BD85347DF61C5CDCC0EB9FF04DDE1EA1FA3101" \
         >> "${config.xdg.dataHome}/gnupg/sshcontrol"
  '';
}
