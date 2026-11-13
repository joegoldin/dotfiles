{
  inputs,
  pkgs,
  lib,
}:
let
  meta = import ../../_lib/meta.nix;
  aspect = (import ../rex.nix { inherit inputs; }).den.aspects.rex;
  system =
    tailscale:
    (inputs.nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        aspect.nixos
        {
          networking.hostName = "elphael";
          services.tailscale.enable = tailscale;
          users.users.${meta.username}.isNormalUser = true;
          system.stateVersion = "26.05";
        }
      ];
    }).config;
  nixos = system true;
  noTailscale = system false;
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
  linuxNoTailscale = home pkgs.stdenv.hostPlatform.system noTailscale;
  mac = home "aarch64-darwin" { networking.hostName = "torrent"; };
  checkSystem =
    config:
    assert config.users.users.${meta.username}.linger;
    assert builtins.elem config.services.rex.package config.environment.systemPackages;
    assert !config.services.rex.enable;
    assert !config.services.rex.loginServer.enable;
    assert !config.services.rex.tailscale.enable;
    assert !config.services.rex.tailscaleServe.enable;
    assert !config.services.rex.loginServer.tailscaleServe.enable;
    assert config.services.rex.loginServer.extraListen == [ ];
    assert config.services.rex.loginServer.accounts == { };
    assert !(config.systemd.services ? rex-login-server);
    assert !(config.systemd.services ? rex-tailscale-serve);
    assert !(builtins.elem 7297 config.networking.firewall.allowedTCPPorts);
    assert !(config.networking.firewall.interfaces ? tailscale0);
    true;
  checkHome =
    config:
    let
      lua = config.xdg.configFile."rex/dotfiles.lua".text;
    in
    assert config.programs.rex.enable;
    assert !config.services.rex.enable;
    assert !(config.systemd.user.services ? rex);
    assert !(config.home.shellAliases ? restart-rex-server);
    assert lib.hasInfix ''endpoint = "ssh://erdtree",'' lua;
    assert !(lib.hasInfix "http://" lua);
    assert !(lib.hasInfix ".ts.net" lua);
    assert !(lib.hasInfix ":7297" lua);
    true;
in
assert checkSystem nixos;
assert checkSystem noTailscale;
assert checkHome linux;
assert checkHome linuxNoTailscale;
assert checkHome mac;
assert !(lib.hasInfix ''label = "elphael",'' linux.xdg.configFile."rex/dotfiles.lua".text);
assert lib.hasInfix ''endpoint = "ssh://elphael",'' mac.xdg.configFile."rex/dotfiles.lua".text;
assert mac.programs.rex.package == null;
pkgs.runCommand "rex-service-tests" { } ''
  touch "$out"
''
