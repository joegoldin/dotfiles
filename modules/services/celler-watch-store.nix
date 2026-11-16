# Upload new store paths independently of the Nix build scheduler.
{ inputs, ... }:
let
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
  attic = import "${inputs.dotfiles-secrets}/attic.nix";
in
{
  den.aspects.celler-watch-store.nixos =
    { config, pkgs, ... }:
    let
      celler = inputs.celler.packages.${pkgs.stdenv.hostPlatform.system}.celler;
    in
    {
      systemd.services.celler-watch-store = {
        description = "Upload new Nix store paths to Celler";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "agenix.service"
          "nix-daemon.socket"
        ];
        unitConfig.StartLimitIntervalSec = 0;
        serviceConfig = {
          DynamicUser = true;
          LoadCredential = "celler-token:${config.age.secrets.attic-token.path}";
          RuntimeDirectory = "celler-watch-store";
          Environment = "XDG_CONFIG_HOME=/run/celler-watch-store";
          Restart = "always";
          RestartSec = 30;
          UMask = "0077";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
        };
        # Only the credential path is written to the config, never its contents.
        script = ''
          mkdir -p "$XDG_CONFIG_HOME/celler"
          cat > "$XDG_CONFIG_HOME/celler/config.toml" <<EOF
          [servers.default-server]
          endpoint = "https://${domains.atticDomain}/"
          token-file = "$CREDENTIALS_DIRECTORY/celler-token"
          EOF
          exec ${celler}/bin/celler watch-store --jobs 5 default-server:${attic.cacheName}
        '';
      };
    };
}
