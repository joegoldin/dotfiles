{
  inputs,
  pkgs,
  lib,
}:
let
  meta = import ../../_lib/meta.nix;
  aspect = (import ../rex.nix { inherit inputs; }).den.aspects.rex;
  nixos =
    (inputs.nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        aspect.nixos
        {
          networking.hostName = "rex-test";
          services.tailscale.enable = true;
          users.users.${meta.username}.isNormalUser = true;
          system.stateVersion = "26.05";
        }
      ];
    }).config;
  home =
    system: osConfig:
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs { inherit system; };
      extraSpecialArgs = { inherit osConfig; };
      modules = [
        aspect.homeManager
        {
          home = {
            inherit (meta) username;
            homeDirectory =
              if lib.hasSuffix "-darwin" system then "/Users/${meta.username}" else "/home/${meta.username}";
            stateVersion = "26.05";
          };
        }
      ];
    }).config;
  linux = home pkgs.stdenv.hostPlatform.system nixos;
  mac = home "aarch64-darwin" { networking.hostName = "torrent"; };
  login = nixos.services.rex.loginServer;
in
assert !linux.services.rex.enable;
assert !(builtins.hasAttr "rex" linux.systemd.user.services);
assert !nixos.services.rex.enable;
assert login.enable && login.tailscaleServe.enable;
assert login.tailscaleServe.httpsPort == 7297;
assert nixos.systemd.services.rex-login-server.wantedBy == [ "multi-user.target" ];
assert lib.hasInfix "--https=7297"
  nixos.systemd.services.rex-tailscale-serve.serviceConfig.ExecStart;
assert !(lib.hasInfix ":8443" linux.xdg.configFile."rex/dotfiles.lua".text);
assert !login.allowAnonymous;
assert builtins.attrNames login.accounts == [ meta.username ];
assert builtins.length login.accounts.${meta.username}.principals == 2;
assert lib.hasPrefix "tailscale:" (builtins.head login.accounts.${meta.username}.principals);
assert builtins.elem "tailscale:tag:rex-host" login.accounts.${meta.username}.principals;
assert login.extraListen == [ "tailnet://:7298" ];
assert lib.hasInfix "tailnet://:7298"
  nixos.systemd.services.rex-login-server.serviceConfig.ExecStart;
assert nixos.networking.firewall.interfaces.tailscale0.allowedTCPPorts == [ 7298 ];
assert !(builtins.elem 7298 nixos.networking.firewall.allowedTCPPorts);
assert !mac.services.rex.enable;
assert mac.programs.rex.package == null;
assert !(lib.hasInfix "-tagged" mac.xdg.configFile."rex/dotfiles.lua".text);
assert !(lib.hasInfix ":7298" mac.xdg.configFile."rex/dotfiles.lua".text);
pkgs.runCommand "rex-service-tests" { } ''
  touch "$out"
''
