{
  inputs,
  packageSets,
  pkgs,
  lib,
}:
let
  meta = import ../../_lib/meta.nix;
  aspect =
    (import ../rex.nix {
      inherit inputs lib;
      config.flake = {
        nixosConfigurations = {
          linux-server.config.home-manager.users.${meta.username} = {
            dotfiles.rex.listed = true;
            services.rex.enable = true;
          };
          unlisted-server.config.home-manager.users.${meta.username}.services.rex.enable = true;
          disabled-server.config.home-manager.users.${meta.username} = {
            dotfiles.rex.listed = true;
            services.rex.enable = false;
          };
          installer.config = { };
        };
        darwinConfigurations = {
          native-app.config.home-manager.users.${meta.username} = {
            dotfiles.rex.listed = true;
            programs.rex = {
              enable = true;
              package = null;
            };
          };
          cli-only.config.home-manager.users.${meta.username} = {
            dotfiles.rex.listed = true;
            programs.rex = {
              enable = true;
              package = "cli";
            };
          };
        };
      };
    }).den.aspects.rex;
  listedAspect = (import ../rex-listed.nix { den.aspects.rex = aspect; }).den.aspects.rex-listed;
  system =
    tailscale:
    (inputs.nixpkgs.lib.nixosSystem {
      system = pkgs.stdenv.hostPlatform.system;
      modules = [
        aspect.nixos
        {
          services.tailscale.enable = tailscale;
          users.users.${meta.username}.isNormalUser = true;
          system.stateVersion = "26.05";
        }
      ];
    }).config;
  nixos = system true;
  noTailscale = system false;
  home =
    system: hostName:
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = packageSets.${system}.plain;
      extraSpecialArgs.osConfig.networking.hostName = hostName;
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
      ]
      ++ lib.optional (lib.hasSuffix "-darwin" system) listedAspect.homeManager;
    }).config;
  linux = home pkgs.stdenv.hostPlatform.system "linux-server";
  unlisted = home pkgs.stdenv.hostPlatform.system "unlisted-server";
  mac = home "aarch64-darwin" "native-app";
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
    isLinux: expectedPeers: config:
    let
      lua = config.xdg.configFile."rex/dotfiles.lua".text;
    in
    assert config.programs.rex.enable;
    assert config.services.rex.enable == isLinux;
    assert (config.systemd.user.services ? rex) == isLinux;
    assert
      isLinux
      -> (
        config.systemd.user.services.rex.Unit.X-SwitchMethod == "restart"
        && builtins.elem "default.target" config.systemd.user.services.rex.Install.WantedBy
        && config.services.rex.extraListen == [ ]
        && !config.services.rex.tailscale.enable
      );
    assert !(config.home.shellAliases ? restart-rex-server);
    assert lib.hasPrefix (builtins.readFile ./ghostty.lua) lua;
    assert lib.all (host: lib.hasInfix ''endpoint = "ssh://${host}",'' lua) expectedPeers;
    assert builtins.length (lib.splitString "rex.host {" lua) == builtins.length expectedPeers + 1;
    true;
in
assert checkSystem nixos;
assert checkSystem noTailscale;
assert checkHome true [ "native-app" ] linux;
assert checkHome true [ "linux-server" "native-app" ] unlisted;
assert checkHome false [ "linux-server" ] mac;
assert !(unlisted.dotfiles.rex.listed or false);
assert mac.dotfiles.rex.listed;
assert mac.programs.rex.package == null;
pkgs.runCommand "rex-service-tests" { } ''
  touch "$out"
''
