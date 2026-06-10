# Cross-platform packages shared between workstations (darwin, joe-desktop,
# office-pc). NOT imported by ./default.nix — workstation hosts import this
# file explicitly so cloud VMs stay lean.
#
# Host packages/ files hold ONLY platform-specific packages; anything that
# runs on both mac and linux belongs here (or in ./default.nix if the cloud
# hosts should get it too).
{ pkgs, lib, ... }:
let
  inherit (pkgs) unstable;

  packageGroups = with pkgs; {
    cli = [
      asdf-vm # asdf
      btop
      unstable.calcurse
      chromedriver
      claude-container # needs native build, no QEMU — workstations only
      cloudflared
      cmake
      croc
      dive
      docker-compose
      unstable.dumbpipe
      entr
      fastfetch
      unstable.ffmpeg
      ghostscript
      unstable.gradle_9
      inetutils # telnet
      kubefwd
      unstable.maven
      mysql84 # mysql
      nodejs # node
      okteto
      profanity
      protobuf
      rclone
      redis
      ruby
      saml2aws
      silver-searcher # the_silver_searcher
      sops
      sshpass
      stern
      tailspin
      terraform
      timg
      universal-ctags
      visidata
      watchman

      python3Packages.docutils # docutils
      python3Packages.keyring # keyring
      python3Packages.virtualenv # virtualenv
    ];

    gui = [
      fontforge
      mpv
      pidgin
      scrcpy
    ];
  };
in
{
  home.packages = lib.flatten (lib.attrValues packageGroups);
}
