# Login keys stay on each workstation; agenix keeps its unattended identities.
{ inputs, ... }:
let
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
in
{
  den.aspects.local-ssh.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      signingKey = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
      allowedSigners = "${config.xdg.configHome}/git/allowed_signers";
      setAgentEnvironment = ''
        /bin/launchctl setenv SSH_AUTH_SOCK "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${config.services.ssh-agent.socket}"
      '';
    in
    {
      # GUI apps need the local socket both after activation and on later logins.
      home.activation.localSSHAgentEnvironment = lib.mkIf pkgs.stdenv.isDarwin (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${setAgentEnvironment}
        ''
      );
      launchd.agents.local-ssh-environment = lib.mkIf pkgs.stdenv.isDarwin {
        enable = true;
        config = {
          ProgramArguments = [
            (lib.getExe pkgs.bash)
            "-c"
            setAgentEnvironment
          ];
          RunAtLoad = true;
        };
      };

      services.ssh-agent = {
        enable = true;
        defaultMaximumIdentityLifetime = 3600;
      };
      xdg.configFile."git/allowed_signers".text = ''
        joe@joegold.in ${keys.elphael}
        joe@joegold.in ${keys.torrent}
      '';

      programs = {
        # Public-key paths make signing use the unlocked agent, not another signer.
        git = {
          signing = {
            key = signingKey;
            format = "ssh";
            signer = lib.getExe' pkgs.openssh "ssh-keygen";
            signByDefault = true;
          };
          settings.gpg.ssh.allowedSignersFile = allowedSigners;
        };
        jujutsu.settings.signing = {
          backend = "ssh";
          behavior = "own";
          key = signingKey;
          backends.ssh = {
            program = lib.getExe' pkgs.openssh "ssh-keygen";
            allowed-signers = allowedSigners;
          };
        };
        ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."*" = {
            IdentityAgent = "SSH_AUTH_SOCK";
            IdentityFile = "~/.ssh/id_ed25519";
            IdentitiesOnly = true;
            AddKeysToAgent = "1h";
            ForwardAgent = false;
          };
        };
      };
    };
}
