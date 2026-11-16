{
  inputs,
  config,
  den,
  lib,
  ...
}:
let
  meta = import ../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  loginKeys = [
    keys.${meta.username}
    keys.elphael
    keys.torrent
  ];
  hosts = lib.concatLists (
    lib.mapAttrsToList (
      system: hosts: lib.mapAttrsToList (name: _: { inherit name system; }) hosts
    ) den.hosts
  );
  checkHost =
    { name, system }:
    let
      isDarwin = lib.hasSuffix "-darwin" system;
      configurations =
        if isDarwin then config.flake.darwinConfigurations else config.flake.nixosConfigurations;
      host = configurations.${name}.config;
      user = host.users.users.${meta.username};
      hasLoginKeys = actual: lib.all (key: builtins.elem key actual) loginKeys;
    in
    assert lib.assertMsg (hasLoginKeys user.openssh.authorizedKeys.keys)
      "${name}: user login keys missing";
    if isDarwin then
      lib.assertMsg (user.home == "/Users/${meta.username}") "${name}: user home missing"
    else
      lib.assertMsg (
        user.isNormalUser
        && user.uid == 1000
        && hasLoginKeys host.users.users.root.openssh.authorizedKeys.keys
        && (host.boot.initrd.network.ssh.enable -> hasLoginKeys host.boot.initrd.network.ssh.authorizedKeys)
      ) "${name}: user account or recovery keys missing";
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.den-user-host-content =
        assert lib.assertMsg den.migrations.user-host-content.acknowledged
          "Den transition defaults must be disabled";
        assert lib.all checkHost hosts;
        pkgs.runCommand "den-user-host-content-tests" { } ''
          touch "$out"
        '';
    };
}
