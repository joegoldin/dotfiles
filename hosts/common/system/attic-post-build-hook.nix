{
  config,
  dotfiles-secrets,
  ...
}:
let
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
in
{
  services.attic-post-build-hook = {
    enable = true;
    serverName = "default-server";
    inherit (attic) cacheName;
    serverEndpoint = "https://${domains.atticDomain}/";
    tokenFile = config.age.secrets.attic-token.path;
    serverHostnames = [ "bastion" ];
  };
}
