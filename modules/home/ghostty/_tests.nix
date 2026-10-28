# Evaluate with: import ./_tests.nix { inherit (pkgs) lib; }
{ lib }:
let
  evaluate =
    isDarwin:
    let
      system = if isDarwin then "aarch64-darwin" else "x86_64-linux";
      pkgs = {
        stdenv.hostPlatform = { inherit isDarwin system; };
        herdtty = "/test/herdtty";
        duti = "/test/duti";
        writeShellScriptBin = name: _: "/test/${name}";
      };
      config = {
        home.homeDirectory = "/home/test";
        home.profileDirectory = "/test/profile";
        xdg.configHome = "/home/test/.config";
        programs.ghostty.package = "/test/ghostty";
      };
      args = {
        inherit pkgs config;
        lib = lib // {
          hm.dag.entryAfter = after: data: { inherit after data; };
        };
      };
      ghostty =
        (import ./default.nix {
          inputs.ghostty.packages.${system}.default = config.programs.ghostty.package;
        }).den.aspects.ghostty.homeManager
          args;
      herdtty = (import ../herdtty.nix { }).den.aspects.herdtty.homeManager args;
    in
    {
      terminal = ghostty.home.sessionVariables.TERMINAL or null;
      herdttyOwnsTerminal = herdtty.home ? sessionVariables.TERMINAL;
      herdttyOverridesMacDefault = herdtty.home.activation ? herdttyDefaultTerminal;
      terminalService =
        herdtty.xdg.dataFile.content."dbus-1/services/dev.herdtty.terminal.service".text or "";
    };
  linux = evaluate false;
  darwin = evaluate true;
  host = (import ../../hosts/elphael/plasma.nix { inherit lib; }).den.aspects.elphael.homeManager;
  desktop = host.programs.plasma;
  shared = (import ../plasma.nix { inputs = { }; }).den.aspects.plasma.homeManager {
    inherit lib;
    pkgs = { };
  };
  menu =
    if host ? xdg.dataFile."kio/servicemenus/terminal-actions.desktop" then
      builtins.readFile host.xdg.dataFile."kio/servicemenus/terminal-actions.desktop".source
    else
      "";
in
lib.runTests {
  testHerdrTerminalActivation = {
    expr =
      lib.hasInfix "Name=dev.herdtty.terminal" linux.terminalService
      && lib.hasInfix "Exec=/test/profile/bin/herdtty --herdr-terminal=true --gtk-single-instance=true --initial-window=false" linux.terminalService;
    expected = true;
  };
  testNoDuplicateGhosttyMenu = {
    expr = shared.programs.plasma.configFile.kservicemenurc.Show.RunGhosttyDir or true;
    expected = false;
  };
  testNoDuplicateBuiltinMenu = {
    expr = desktop.configFile.dolphinrc.ContextMenu.ShowOpenTerminal or true;
    expected = false;
  };
  testNoDuplicateHerdttyMenu = {
    expr = desktop.configFile.kservicemenurc.Show.RunHerdttyDir or true;
    expected = false;
  };
  testMenuNames = {
    expr =
      lib.hasInfix "Name=Open in Terminal\n" menu && lib.hasInfix "Name=Open in Herdr Terminal\n" menu;
    expected = true;
  };
  testMenuDirectoryArguments = {
    expr =
      lib.hasInfix "Exec=ghostty +new-window --working-directory=%f" menu
      && lib.hasInfix "Exec=herdtty +new-window --class=dev.herdtty.terminal --working-directory=%f" menu;
    expected = true;
  };
  testMenuLocalSingleDirectory = {
    expr = lib.hasInfix "X-KDE-Protocols=file" menu && lib.hasInfix "X-KDE-RequiredNumberOfUrls=1" menu;
    expected = true;
  };
  testLinuxTerminal = {
    expr = linux.terminal;
    expected = "/test/ghostty/bin/ghostty";
  };
  testDarwinTerminal = {
    expr = darwin.terminal;
    expected = "/test/ghostty/bin/ghostty";
  };
  testHerdttyDoesNotOwnTerminal = {
    expr = linux.herdttyOwnsTerminal || darwin.herdttyOwnsTerminal;
    expected = false;
  };
  testHerdttyDoesNotOverrideMacDefault = {
    expr = darwin.herdttyOverridesMacDefault;
    expected = false;
  };
  testKdeTerminal = {
    expr = desktop.configFile.kdeglobals.General.TerminalApplication.content;
    expected = "ghostty";
  };
  testKdeTerminalService = {
    expr = desktop.configFile.kdeglobals.General.TerminalService.content;
    expected = "com.mitchellh.ghostty.desktop";
  };
  testTerminalShortcut = {
    expr = desktop.hotkeys.commands.launch-konsole.command;
    expected = "ghostty";
  };
}
