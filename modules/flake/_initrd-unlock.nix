# `unlock` — a short alias for `systemd-tty-ask-password-agent` in the initrd SSH
# shell (the command that answers the LUKS passphrase prompt on the encrypted
# servers). Imported into every host via den.default.nixos; the mkIf makes it a
# no-op unless the host runs a systemd initrd (i.e. the encrypted + initrd-SSH
# boxes: siofra, erdtree, melina, farum-azula).
{ config, lib, ... }:
{
  boot.initrd.systemd.extraBin.unlock = lib.mkIf config.boot.initrd.systemd.enable (
    lib.getExe' config.boot.initrd.systemd.package "systemd-tty-ask-password-agent"
  );
}
