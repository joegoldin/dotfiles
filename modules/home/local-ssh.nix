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
      loader = import ./_local-ssh/package.nix { inherit pkgs; };
      loadKey = ''
        ${lib.getExe loader} ${lib.escapeShellArg "${config.home.homeDirectory}/.ssh/id_ed25519"} /run/agenix/ssh-key-passphrase
      '';
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
            ''
              set -euo pipefail
              ${setAgentEnvironment}
              export SSH_AUTH_SOCK="$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${config.services.ssh-agent.socket}"
              ${loadKey}
            ''
          ];
          RunAtLoad = true;
        };
      };

      services.ssh-agent = {
        enable = true;
        defaultMaximumIdentityLifetime = null;
      };
      systemd.user.services = lib.mkIf pkgs.stdenv.isLinux {
        # User lingering is enabled for other services; this agent must still
        # stop at desktop logout rather than live for the whole user-manager.
        ssh-agent = {
          Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
          Unit.PartOf = [ "graphical-session.target" ];
        };
        ssh-login-key = {
          Unit = {
            Description = "Unlock the local SSH key for this desktop session";
            Requires = [ "ssh-agent.service" ];
            After = [ "ssh-agent.service" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            Environment = "SSH_AUTH_SOCK=%t/${config.services.ssh-agent.socket}";
            ExecStart = "${lib.getExe loader} ${config.home.homeDirectory}/.ssh/id_ed25519 /run/agenix/ssh-key-passphrase";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
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
            # Manual eviction must last until the next login or explicit add.
            AddKeysToAgent = "no";
            ForwardAgent = false;
          };
        };
      };
    };
}
