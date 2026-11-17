# Server host identities; workstation login keys and agents live in home/local-ssh.nix.
_: {
  den.aspects.ssh-host-keys = {
    nixos.imports = [ ./_ssh-host-keys.nix ];
    darwin = {
      # macOS manages the key files; restrict which identity sshd may offer.
      services.openssh.extraConfig = ''
        HostKeyAlgorithms ssh-ed25519
      '';
    };
  };
}
