{ inputs, ... }:
let
  meta = import ../../_lib/meta.nix;
in
{
  den.aspects.torrent = {
    darwin.age.secrets.vfkit-usb-profile = {
      file = "${inputs.dotfiles-secrets}/vfkit-usb.provisionprofile.age";
      mode = "0400";
      owner = meta.username;
    };

    homeManager =
      { lib, pkgs, ... }:
      let
        vfkit = inputs.agent-skills.packages.${pkgs.stdenv.hostPlatform.system}.vfkit-usb;
        identity = "30D7D473E9D91CAD427BAB52A4566D712F29FABF";
        signApp = pkgs.writeShellScript "vfkit-sign-app" (builtins.readFile ./_vfkit-sign.sh);
      in
      {
        # Like Zen, the build is immutable; the provisioned signature belongs
        # to a writable user copy and uses the Mac's login keychain.
        home.activation.vfkitSignedApp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${signApp} ${vfkit} /run/agenix/vfkit-usb-profile ${identity} "$HOME/Applications/vfkit.app"
        '';
      };
  };
}
