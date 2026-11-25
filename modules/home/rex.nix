# Named Rex aspect: native Mac client and SSH-accessible personal Linux servers.
{
  config,
  inputs,
  lib,
  ...
}:
let
  meta = import ../_lib/meta.nix;
  homeConfig = host: host.config.home-manager.users.${meta.username} or { };
  linuxServers = lib.filterAttrs (
    _: host: (homeConfig host).services.rex.enable or false
  ) config.flake.nixosConfigurations;
  # On Darwin the native app owns the server; Home Manager only exposes its CLI.
  macServers = lib.filterAttrs (
    _: host:
    let
      rex = (homeConfig host).programs.rex;
    in
    (rex.enable or false) && rex.package == null
  ) config.flake.darwinConfigurations;
  hosts = builtins.attrNames (linuxServers // macServers);
in
{
  den.aspects.rex.nixos =
    { config, ... }:
    {
      imports = [ inputs.rex.nixosModules.default ];
      # Keep the personal user service and its sessions alive after logout.
      users.users.${meta.username}.linger = true;
      environment.systemPackages = [ config.services.rex.package ];
    };

  den.aspects.rex.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isMac = pkgs.stdenv.hostPlatform.isDarwin;
      appRex = (import ./_rex/darwin-app.nix).cli;
      rex = if isMac then appRex else lib.getExe config.programs.rex.package;
      configDir = "${config.xdg.configHome}/rex";
      shellInit = ''
        if [ -n "$REX_BIN_DIR" ]; then
          export PATH="$REX_BIN_DIR:$PATH"
        fi
      '';
    in
    {
      imports = [ inputs.rex.homeManagerModules.default ];
      config = {
        services.rex.enable = !isMac;
        # Switches must pick up server updates, even when a server is running.
        # Restarting ends its terminal sessions; macOS remains app-managed.
        systemd.user.services = lib.mkIf (!isMac) {
          rex.Unit.X-SwitchMethod = "restart";
        };
        programs = {
          rex = {
            enable = true;
            # Use the binary bundled with the app, so GUI and CLI stay in sync.
            package = lib.mkIf isMac null;
            sshGuard = !isMac && config.programs.ssh.enable;
          };
          fish.interactiveShellInit = lib.mkAfter ''
            if set -q REX_BIN_DIR
              fish_add_path --path --prepend --move $REX_BIN_DIR
            end
          '';
          bash.initExtra = lib.mkAfter shellInit;
          zsh.initContent = lib.mkAfter shellInit;
        };
        home = {
          packages = lib.optional isMac (
            pkgs.writeShellScriptBin "rex" ''
              exec ${lib.escapeShellArg appRex} "$@"
            ''
          );
          # init.lua remains writable. The loader is merged ahead of local Lua,
          # which can override managed defaults without being overwritten.
          activation.rexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            run ${pkgs.python3}/bin/python3 ${./_rex/merge-config.py} \
              ${lib.escapeShellArg "${configDir}/init.lua"} \
              ${lib.escapeShellArg "${configDir}/dotfiles.lua"} \
              ${lib.escapeShellArg rex}
          '';
        };
        xdg.configFile."rex/dotfiles.lua".text =
          builtins.readFile ./_rex/ghostty.lua
          + "\n"
          + lib.concatMapStrings (host: ''
            rex.host {
              label = ${builtins.toJSON host},
              endpoint = ${builtins.toJSON "ssh://${host}"},
            }
          '') hosts;
      };
    };
}
