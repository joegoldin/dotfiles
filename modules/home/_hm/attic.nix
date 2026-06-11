{ dotfiles-secrets, ... }:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
in
{
  programs.attic-client = {
    enable = true;
    defaultServer = "default-server";
    servers.default-server = {
      endpoint = "https://${domains.atticDomain}/";
      tokenPath = "/run/agenix/attic-token";
      aliases = [ attic.cacheName ];
    };
  };
}
