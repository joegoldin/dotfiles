{ dotfiles-secrets, ... }:
let
  domains = import "${dotfiles-secrets}/domains.nix";
in
{
  xdg.configFile."attic/config.toml".text = ''
    default-server = "turnin"

    [servers.turnin]
    endpoint = "https://${domains.atticDomain}/"
    token_file = "/run/agenix/attic-token"
  '';
}
