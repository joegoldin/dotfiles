# Guard the migration boundaries: no synchronous uploads and no fresh database.
{
  config,
  inputs,
  lib,
  ...
}:
let
  hosts = config.flake.nixosConfigurations;
  caches = import ../_lib/ci-caches.nix inputs;
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
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
      && lib.hasInfix "endpoint = \"${caches.cellerURL}/\"" service.script
      && host.nix.settings.netrc-file == caches.cellerNetrc
    ) "${name}: Celler uploads must be supervised and use runtime credentials, never a build hook";
  server = hosts.siofra.config;
  ci = hosts.erdtree.config;
  mac = config.flake.darwinConfigurations.torrent.config;
  macWatcher = mac.launchd.daemons.celler-watch-store;
in
{
  perSystem = { pkgs, ... }: {
    checks.celler-migration =
      assert lib.all checkWatcher watchers;
      assert (mac.nix.settings.post-build-hook or "") == "";
      assert macWatcher.serviceConfig.RunAtLoad && macWatcher.serviceConfig.KeepAlive;
      assert macWatcher.serviceConfig.ThrottleInterval == 30;
      assert macWatcher.serviceConfig.UserName == "root";
      assert macWatcher.serviceConfig.Umask == 63;
      assert macWatcher.environment.XDG_CONFIG_HOME == "/var/run/celler-watch-store";
      assert lib.hasInfix "celler watch-store --jobs 5 default-server:" macWatcher.script;
      assert lib.hasInfix "token-file = \"${mac.age.secrets.attic-token.path}\"" macWatcher.script;
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
      assert server.services.cellerd.settings.listen == "127.0.0.1:8081";
      assert server.services.cellerd.settings.api-endpoint == "${caches.cellerURL}/";
      assert !(builtins.hasAttr domains.atticDomain server.services.caddy.virtualHosts);
      assert lib.hasInfix "tailscale serve --yes --https=${caches.cellerPort}"
        server.systemd.services.celler-tailnet.serviceConfig.ExecStart;
      assert mac.nix.settings.netrc-file == caches.cellerNetrc;
      assert !(server.services.cellerd.settings ? chunking);
      assert ci.services.hydra.enable && ci.services.hydra.useSubstitutes;
      assert ci.services.hydra.listenHost == "127.0.0.1" && ci.services.hydra.hydraURL == caches.hydraURL;
      assert lib.hasInfix "binary_cache_secret_key_file = ${ci.age.secrets.hydra-cache-signing-key.path}"
        ci.services.hydra.extraConfig;
      assert lib.hasInfix "tailscale serve --yes --https=${caches.hydraPort}"
        ci.systemd.services.hydra-tailnet.serviceConfig.ExecStart;
      assert !ci.services.postgresql.enableTCPIP;
      assert !(builtins.hasAttr "scarab" config.flake.hydraJobs);
      assert !(lib.elem caches.hydraURL ci.nix.settings.extra-substituters);
      assert lib.any (lib.hasPrefix "${caches.cellerURL}/") ci.nix.settings.extra-substituters;
      assert !(ci.systemd.services ? garnixServer) && !(ci.systemd.services ? garnix-provisionerd);
      assert hosts.farum-azula.config.nix.sshServe.protocol == "ssh";
      pkgs.runCommand "celler-migration-checks"
        {
          nativeBuildInputs = [
            pkgs.bash
            pkgs.gawk
            pkgs.python3
          ];
          # Inspect the Darwin-generated files without realizing Darwin binaries
          # on the Linux check runner.
          CELLER_DARWIN_SCRIPT = builtins.unsafeDiscardStringContext macWatcher.script;
          CELLER_DARWIN_PLIST =
            builtins.unsafeDiscardStringContext
              mac.environment.launchDaemons."org.nixos.celler-watch-store.plist".text;
          CELLER_DARWIN_EXECUTABLE = builtins.unsafeDiscardStringContext "${inputs.celler.packages.aarch64-darwin.celler}/bin/celler";
          CELLER_DARWIN_TOKEN_PATH = mac.age.secrets.attic-token.path;
        }
        ''
          python3 ${../services/_celler/test_darwin_watcher.py} -v
          bash ${../services/_celler/test-netrc.sh} ${../services/_celler/migrate-netrc.awk}
          touch "$out"
        '';
  };
}
