# Push builds to the attic cache after each local build (workstations and
# the steam deck; servers and cloud-proxy don't push).
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
  domains = import "${dotfiles-secrets}/domains.nix";
  attic = import "${dotfiles-secrets}/attic.nix";
in
{
  den.aspects.attic-post-build-hook.nixos =
    { config, ... }:
    {
      imports = [ inputs.nix-attic-infra.nixosModules.attic-post-build-hook ];
      services.attic-post-build-hook = {
        enable = true;
        serverName = "default-server";
        inherit (attic) cacheName;
        serverEndpoint = "https://${domains.atticDomain}/";
        tokenFile = config.age.secrets.attic-token.path;
        serverHostnames = [ "bastion" ];
      };
    };
}
