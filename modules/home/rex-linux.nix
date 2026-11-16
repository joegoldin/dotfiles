# Linux GUI only. Server lifetime belongs to the existing shared Rex aspect.
{ inputs, ... }:
{
  den.aspects.rex-linux.homeManager =
    {
      lib,
      pkgs,
      ...
    }:
    let
      package = inputs.rex-rune.packages.${pkgs.stdenv.hostPlatform.system}.default;
      ghostty = (import ./ghostty/_settings.nix { inherit lib; }).baseSettings;
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Keep the client's own compiler/dependency pins, not the host nixpkgs.
      home.packages = [ package ];
      # The upstream default font need not be installed on this machine.
      # Preserve the pinned taskbar ID while matching the upstream window/icon.
      xdg.desktopEntries."dev.shuv.rex-linux" = {
        name = "Rex Rune";
        genericName = "Terminal Workspace";
        exec = "${lib.getExe package} --font \"${ghostty.font-family}\"";
        icon = "dev.shuv.rex-rune";
        terminal = false;
        categories = [
          "System"
          "TerminalEmulator"
        ];
        settings.StartupWMClass = "dev.shuv.rex-rune";
      };
    };
}
