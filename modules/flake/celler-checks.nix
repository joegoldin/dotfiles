# Guard the migration boundaries: no synchronous uploads and no fresh database.
{ config, lib, ... }:
let
  hosts = config.flake.nixosConfigurations;
  watchers = [
    "elphael"
    "malenia"
    "volcano-manor"
  ];
  checkWatcher =
    name:
    let
      host = hosts.${name}.config;
      service = host.systemd.services.celler-watch-store;
    in
    lib.assertMsg (
      (host.nix.settings.post-build-hook or "") == ""
      && !(host.systemd.services ? attic-watch-store)
      && builtins.elem "multi-user.target" service.wantedBy
      && service.serviceConfig.Restart == "always"
      && service.serviceConfig.DynamicUser
      && lib.hasPrefix "celler-token:/run/agenix/" service.serviceConfig.LoadCredential
      && lib.hasInfix "celler watch-store --jobs 5 default-server:" service.script
      && lib.hasInfix "token-file = \"$CREDENTIALS_DIRECTORY/celler-token\"" service.script
    ) "${name}: Celler uploads must be supervised and use runtime credentials, never a build hook";
  server = hosts.siofra.config;
in
{
  perSystem = { pkgs, ... }: {
    checks.celler-migration =
      assert lib.all checkWatcher watchers;
      assert !(server.services ? atticd) || !(server.services.atticd.enable or false);
      assert server.services.cellerd.enable;
      assert
        server.services.cellerd.settings.database.url == "sqlite:///var/lib/atticd/server.db?mode=rw";
      assert server.systemd.services.cellerd.serviceConfig.StateDirectory == "atticd";
      assert builtins.elem "ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64"
        server.systemd.services.cellerd.serviceConfig.UnsetEnvironment;
      assert
        server.services.cellerd.settings.jwt.rs256-public-key-file
        == "/run/celler-jwt-public-key/public-key.pem";
      assert server.services.cellerd.settings.listen == "[::1]:8081";
      assert !(server.services.cellerd.settings ? chunking);
      pkgs.runCommand "celler-migration-checks" { } ''
        touch "$out"
      '';
  };
}
