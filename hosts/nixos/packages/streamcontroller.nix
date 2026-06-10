{ pkgs, lib, ... }:
let
  streamcontroller = import ../../common/system/streamcontroller.nix { inherit pkgs; };
in
{
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
    streamcontroller.package
  ];

  xdg.configFile."autostart/StreamController.desktop".text = streamcontroller.autostartDesktopEntry;
}
