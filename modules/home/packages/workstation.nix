# Cross-platform packages shared between workstations (darwin, elphael,
# volcano-manor). NOT imported by ./default.nix; workstation hosts import this
# file explicitly so cloud VMs stay lean.
#
# Host packages/files hold ONLY platform-specific packages; anything that
# runs on both mac and linux belongs here (or in ./default.nix if the cloud
# hosts should get it too).
{ den, ... }:
{
  # day-sync's rendered config travels with the workstations (see
  # ../../ai/day-sync.nix).
  den.aspects.workstation-packages.includes = [ den.aspects.day-sync ];

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
          fastfetch
        ];

        build-tools = [
          cmake
          entr
          unstable.gradle_9
          unstable.maven
          # lowPrio: the common python env propagates python protobuf, which ships
          # the same include/google/protobuf headers; let the env win in buildEnv.
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
          claude-container # needs native build, no QEMU; workstations only
          dive
          docker-compose
          kubefwd
          okteto
          stern
        ];

        infra = [
          cloudflared
          google-cloud-sdk # gcloud; needed by `gws auth setup`
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
          (lib.lowPrio inetutils) # telnet; lowPrio so iputils wins the bin/ping collision
          rclone
          sshpass
        ]
        ++ lib.optionals stdenv.hostPlatform.isLinux [
          # linux-only (needs libcap/prctl); macOS ships its own BSD ping
          iputils # ping (gping needs iputils ping, not inetutils's)
        ];

        media = [
          unstable.ffmpeg
          ghostscript
          timg
        ];

        misc = [
          unstable.calcurse
          chromedriver
          unstable.gws # Google Workspace CLI (calendar, drive, docs, sheets, slides)
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

      # gws (Google Workspace CLI, `misc` group above): point it at the shared
      # OAuth credentials on hosts that deploy the agenix secret (elphael,
      # torrent); the test keeps it a no-op elsewhere.
      programs.fish.interactiveShellInit = ''
        if test -r /run/agenix/gws-credentials
            set -gx GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE /run/agenix/gws-credentials
        end
      '';
    };
}
