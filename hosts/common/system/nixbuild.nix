# nixbuild.net distributed builder.
#
# Authenticates via the user's 1Password SSH agent — the nix-daemon (root)
# can connect to the user-owned agent socket. Requires that 1Password is
# unlocked and the relevant SSH key has been registered with nixbuild.net
# (via `nixbuild` → `ssh-keys add "<pubkey>"`).
{ username, ... }:
{
  programs.ssh.knownHosts.nixbuild = {
    hostNames = [ "eu.nixbuild.net" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
  };

  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
      PubkeyAcceptedKeyTypes ssh-ed25519
      ServerAliveInterval 60
      IdentityAgent /home/${username}/.1password/agent.sock
  '';

  nix = {
    distributedBuilds = true;
    # Let the remote builder fetch substitutes itself instead of pushing
    # the full closure over SSH from the local machine.
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "x86_64-linux";
        maxJobs = 100;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
        ];
      }
    ];
  };
}
