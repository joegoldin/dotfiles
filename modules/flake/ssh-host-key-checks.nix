{ config, lib, ... }:
let
  checkHost =
    name: host:
    let
      ssh = host.config.services.openssh;
    in
    lib.assertMsg (
      ssh.enable
      -> (
        ssh.hostKeys == [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ]
        && ssh.settings.HostKeyAlgorithms == "ssh-ed25519"
        && builtins.elem "hmac-sha2-256" ssh.settings.Macs
        && ssh.settings.Ciphers != [ ]
        && lib.all (
          cipher:
          builtins.elem cipher [
            "chacha20-poly1305@openssh.com"
            "aes256-gcm@openssh.com"
            "aes128-gcm@openssh.com"
          ]
        ) ssh.settings.Ciphers
      )
    ) "${name}: SSH must retain Ed25519 identity and offer AEAD-only SwiftNIO-compatible transport";
  hostChecks = lib.mapAttrsToList checkHost config.flake.nixosConfigurations;
  darwinChecks = lib.mapAttrsToList (
    name: host:
    lib.assertMsg (
      host.config.services.openssh.enable
      -> lib.hasInfix "HostKeyAlgorithms ssh-ed25519" host.config.services.openssh.extraConfig
    ) "${name}: SSH must offer only Ed25519 host identities"
  ) config.flake.darwinConfigurations;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.ssh-host-keys =
        assert lib.all (check: check) (hostChecks ++ darwinChecks);
        pkgs.runCommand "ssh-host-key-tests" { } ''
          touch "$out"
        '';
    };
}
