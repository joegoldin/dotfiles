{ inputs, ... }:
{
  den.aspects.twindesk.homeManager =
    { pkgs, ... }:
    let
      package =
        if pkgs.stdenv.hostPlatform.isDarwin then
          pkgs.callPackage ./_twindesk/darwin.nix { source = inputs.twindesk; }
        else
          inputs.twindesk.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
            # Upstream's flake omits translations required at startup.
            postInstall = (old.postInstall or "") + ''
              cp -R shared/lang "$out/share/twindesk/shared/"
              wrapProgram "$out/bin/twindesk" --run 'umask 077' \
                --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.wl-clipboard ]}
            '';
          });
    in
    {
      home.packages = [ package ];
    };
}
