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
assert login.enable && !login.tailscaleServe.enable;
assert nixos.systemd.services.rex-login-server.wantedBy == [ "multi-user.target" ];
# A running tailscaled unit does not guarantee its addresses are bindable yet.
assert
  nixos.systemd.services.rex-login-server.serviceConfig.ExecStartPre == [
    "${lib.getExe nixos.services.tailscale.package} wait --timeout=60s"
  ];
assert !(builtins.hasAttr "rex-tailscale-serve" nixos.systemd.services);
assert
  !(lib.hasInfix "tailnet-serve://" nixos.systemd.services.rex-login-server.serviceConfig.ExecStart);
assert !(lib.hasInfix ":8443" linux.xdg.configFile."rex/dotfiles.lua".text);
assert !login.allowAnonymous;
assert builtins.attrNames login.accounts == [ meta.username ];
assert login.accounts.${meta.username}.principals == [ "tailscale:tag:full-access" ];
assert login.extraListen == [ "tailnet://:7297" ];
assert lib.hasInfix "tailnet://:7297"
  nixos.systemd.services.rex-login-server.serviceConfig.ExecStart;
assert nixos.networking.firewall.interfaces.tailscale0.allowedTCPPorts == [ 7297 ];
assert !(builtins.elem 7297 nixos.networking.firewall.allowedTCPPorts);
assert !mac.services.rex.enable;
assert mac.programs.rex.package == null;
assert !(lib.hasInfix "-tagged" mac.xdg.configFile."rex/dotfiles.lua".text);
assert !(lib.hasInfix ":7298" mac.xdg.configFile."rex/dotfiles.lua".text);
assert lib.hasInfix ''endpoint = "http://${meta.username}@elphael.''
  mac.xdg.configFile."rex/dotfiles.lua".text;
assert lib.hasInfix ":7297" mac.xdg.configFile."rex/dotfiles.lua".text;
pkgs.runCommand "rex-service-tests" { } ''
  touch "$out"
''
