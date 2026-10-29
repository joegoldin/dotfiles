# Keep package auth out of the store while retaining existing cache credentials.
{ inputs, ... }:
let
  meta = import ../_lib/meta.nix;
  keys = import "${inputs.dotfiles-secrets}/keys.nix";
  configure =
    isDarwin:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      supported = builtins.hasAttr config.networking.hostName keys;
      destination = "/etc/nix/rex-netrc";
      cacheGroup = config.age.secrets.attic-netrc.group or "root";
      cacheMode = config.age.secrets.attic-netrc.mode or "0400";
      cache = lib.optionalString (config.age.secrets ? attic-netrc) ''
        cat ${lib.escapeShellArg config.age.secrets.attic-netrc.path} >> "$temporary"
        printf '\n' >> "$temporary"
      '';
      combine = ''
        (
          set -eu
          umask 077
          temporary=$(${pkgs.coreutils}/bin/mktemp /etc/nix/.rex-netrc.XXXXXX)
          trap 'rm -f "$temporary"' EXIT
          ${cache}
          cat ${lib.escapeShellArg config.age.secrets.rex-netrc.path} >> "$temporary"
          chmod ${cacheMode} "$temporary"
          chown ${meta.username}:${cacheGroup} "$temporary"
          mv -f "$temporary" ${destination}
        )
      '';
    in
    lib.mkIf supported (
      {
        age.secrets.rex-netrc = {
          file = "${inputs.dotfiles-secrets}/rex-netrc.age";
          mode = "0400";
          owner = meta.username;
        };
        # Nix accepts one netrc file; merge, rather than replace, cache auth.
        nix.settings.netrc-file = lib.mkForce destination;
      }
      // (
        if isDarwin then
          {
            # agenix decrypts asynchronously in launchd, not during activation. Its
            # script ends with exit 0, so a success-only EXIT trap runs after decrypt
            # and chown, including at boot, without racing a postActivation script.
            launchd.daemons.activate-agenix.script = lib.mkBefore ''
              trap 'if [ "$?" -eq 0 ]; then ${pkgs.writeShellScript "rex-netrc" combine}; fi' EXIT
            '';
          }
        else
          {
            system.activationScripts.rexNetrc = {
              deps = [ "agenix" ];
              text = combine;
            };
          }
      )
    );
in
{
  den.aspects.rex = {
    nixos = {
      imports = [
        inputs.agenix.nixosModules.default
        (configure false)
      ];
    };
    darwin = {
      imports = [
        inputs.agenix.darwinModules.default
        (configure true)
      ];
    };
  };
}
