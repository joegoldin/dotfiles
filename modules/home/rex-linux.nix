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
      package = inputs.rex-rune.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        nativeCheckInputs = (old.nativeCheckInputs or [ ]) ++ [ pkgs.procps ];
        postPatch = (old.postPatch or "") + ''
          # Keep Clippy strict until upstream uses byte strings for these arrays.
          substituteInPlace src/platform/fs.rs \
            --replace-fail "[b'\n']" '*b"\n"'
          # The SSH test fixtures need procps from PATH, not /bin/ps in the sandbox.
          substituteInPlace src/ssh/install.rs \
            --replace-fail 'Command::new("/bin/ps")' 'Command::new("ps")'
        '';
      });
      ghostty = (import ./ghostty/_settings.nix { inherit lib; }).baseSettings;
    in
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      # Keep the client's own compiler/dependency pins, not the host nixpkgs.
      home.packages = [ package ];
      # The upstream default font need not be installed on this machine.
      # Match the upstream desktop ID so pinned launchers group with its windows.
      xdg.desktopEntries."dev.shuv.rex-rune" = {
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
