{ inputs, ... }:
let
  caches = import ../_lib/ci-caches.nix inputs;
  domains = import "${inputs.dotfiles-secrets}/domains.nix";

  # Nix's netrc matches the hostname, not the port. Migrate the existing Celler
  # entry locally so no new token or encrypted secret is needed on every host.
  migrate =
    { config, pkgs }:
    pkgs.writeShellScript "celler-netrc" ''
      set -euo pipefail
      umask 077
      tmp=$(${pkgs.coreutils}/bin/mktemp ${caches.cellerNetrc}.XXXXXXXX)
      trap '${pkgs.coreutils}/bin/rm -f -- "$tmp"' EXIT
      ${pkgs.gawk}/bin/awk -v old=${domains.atticDomain} -v new=${caches.cellerHost} \
        -f ${./_celler/migrate-netrc.awk} ${config.age.secrets.attic-netrc.path} > "$tmp" || {
        echo 'Celler netrc: missing legacy cache hostname' >&2
        exit 1
      }
      ${pkgs.coreutils}/bin/mv -f -- "$tmp" ${caches.cellerNetrc}
    '';
in
{
  den.aspects.celler-netrc = {
    os =
      { config, lib, ... }:
      {
        nix.settings.netrc-file = lib.mkIf (config.age.secrets ? attic-netrc) caches.cellerNetrc;
      };

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        system.activationScripts.cellerNetrc = lib.mkIf (config.age.secrets ? attic-netrc) {
          deps = [ "agenix" ];
          text = "${migrate { inherit config pkgs; }}";
        };
      };

    darwin =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # Agenix decrypts asynchronously in this launchd job and ends with
        # an explicit exit, so generate the new file on its successful exit.
        launchd.daemons.activate-agenix.script = lib.mkIf (config.age.secrets ? attic-netrc) (
          lib.mkBefore ''
            trap 'if [ "$?" -eq 0 ]; then ${migrate { inherit config pkgs; }} || exit 1; fi' EXIT
          ''
        );
      };
  };
}
