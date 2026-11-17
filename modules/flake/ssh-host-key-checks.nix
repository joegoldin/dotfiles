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
      )
    ) "${name}: SSH must offer only the existing Ed25519 host identity";
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
