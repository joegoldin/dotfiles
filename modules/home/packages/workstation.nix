# Cross-platform packages shared between workstations (darwin, joe-desktop,
# office-pc). NOT imported by ./default.nix — workstation hosts import this
# file explicitly so cloud VMs stay lean.
#
# Host packages/files hold ONLY platform-specific packages; anything that
# runs on both mac and linux belongs here (or in ./default.nix if the cloud
# hosts should get it too).
{ ... }:
{
  den.aspects.workstation-packages.homeManager =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (pkgs) unstable;

      packageGroups = with pkgs; {
        system = [
          btop
          fastfetch
        ];

        build-tools = [
          cmake
          entr
          unstable.gradle_9
          unstable.maven
          # lowPrio: the common python env propagates python protobuf, which ships
          # the same include/google/protobuf headers — let the env win in buildEnv.
          (lib.lowPrio protobuf)
          universal-ctags
          watchman
        ];

        runtimes = [
          asdf-vm # asdf
          nodejs # node
          ruby

          python3Packages.docutils # docutils
          python3Packages.keyring # keyring
          python3Packages.virtualenv # virtualenv
        ];

        containers = [
          claude-container # needs native build, no QEMU — workstations only
          dive
          docker-compose
          kubefwd
          okteto
          stern
        ];

        infra = [
          cloudflared
          saml2aws
          sops
          terraform
        ];

        databases = [
          mysql84 # mysql
          redis
        ];

        network = [
          croc
          unstable.dumbpipe
          inetutils # telnet
          rclone
          sshpass
        ];

        media = [
          unstable.ffmpeg
          ghostscript
          timg
        ];

        misc = [
          unstable.calcurse
          chromedriver
          profanity
          silver-searcher # the_silver_searcher
          tailspin
          visidata
        ];

        gui = [
          mpv
          pidgin
          scrcpy
        ];
      };
    in
    {
      home.packages = lib.flatten (lib.attrValues packageGroups);
    };
}
