{ den, ... }:
{
  den.aspects.krun.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      krunRuntime = pkgs.runCommand "krun-runtime-${pkgs.crun.version}" { } ''
        mkdir -p "$out/bin"
        ln -s ${lib.getExe pkgs.crun} "$out/bin/krun"
      '';
    in
    {
      assertions = [
        {
          assertion = config.virtualisation.docker.rootless.enable;
          message = "the krun aspect requires rootless Docker";
        }
      ];

      environment.systemPackages = [
        pkgs.crun
        krunRuntime
      ];

      virtualisation.docker.rootless.daemon.settings.runtimes.krun.path = "${krunRuntime}/bin/krun";
    };
}
