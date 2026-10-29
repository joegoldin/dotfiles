# Named Rex aspect: native Mac client and Tailscale Serve login servers.
{ inputs, ... }:
let
  meta = import ../_lib/meta.nix;
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
  hosts = [
    "dectus"
    "elphael"
    "erdtree"
    "farum-azula"
    "gitea"
    "malenia"
    "melina"
    "rennala"
    "roundtable"
    "scarab"
    "siofra"
    "travelboi24"
    "volcano-manor"
  ];
in
{
  den.aspects.rex.nixos =
    { config, lib, ... }:
    {
      imports = [ inputs.rex.nixosModules.default ];
      services.rex.loginServer = lib.mkIf config.services.tailscale.enable {
        enable = true;
        accounts.${meta.username}.principals = [
          "tailscale:${domains.tailscaleUser}"
        ];
        tailscaleServe = {
          enable = true;
          httpsPort = 8443;
        };
      };
    };

  den.aspects.rex.homeManager =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    let
      isMac = pkgs.stdenv.hostPlatform.isDarwin;
      enabled = isMac || (osConfig.services.tailscale.enable or false);
      appRex = "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
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
      config = lib.mkIf enabled {
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
        home.packages = lib.optional isMac (
          pkgs.writeShellScriptBin "rex" ''
            exec ${lib.escapeShellArg appRex} "$@"
          ''
        );
        xdg.configFile."rex/dotfiles.lua".text =
          builtins.readFile ./_rex/ghostty.lua
          + "\n"
          + lib.concatMapStrings (host: ''
            rex.host {
              label = "${host}",
              endpoint = "https://${host}.${lib.removePrefix "elphael." domains.elphaelTailscale}:8443",
            }
          '') (builtins.filter (host: host != osConfig.networking.hostName) hosts);

        # init.lua remains writable. The loader is merged ahead of local Lua,
        # which can override managed defaults without being overwritten.
        home.activation.rexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run ${pkgs.python3}/bin/python3 ${./_rex/merge-config.py} \
            ${lib.escapeShellArg "${configDir}/init.lua"} \
            ${lib.escapeShellArg "${configDir}/dotfiles.lua"} \
            ${lib.escapeShellArg rex}
        '';
      };
    };
}
