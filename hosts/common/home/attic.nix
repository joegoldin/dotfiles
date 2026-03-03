{ dotfiles-secrets, ... }:
let
  domains = import "${dotfiles-secrets}/domains.nix";
in
{
  xdg.configFile."attic/config.toml".text = ''
    default-server = "default-server"

    [servers.default-server]
    endpoint = "https://${domains.atticDomain}/"
    token-file = "/run/agenix/attic-token"
  '';
}
