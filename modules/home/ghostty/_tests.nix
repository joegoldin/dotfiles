# Evaluate with: import ./_tests.nix { inherit (pkgs) lib; }
{ lib }:
let
  evaluate =
    isDarwin:
    let
      system = if isDarwin then "aarch64-darwin" else "x86_64-linux";
      pkgs = {
        stdenv.hostPlatform = {
          inherit isDarwin system;
          isLinux = !isDarwin;
        };
        duti = "/test/duti";
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
          mkIf = condition: content: if condition then content else { };
          hm.dag.entryAfter = after: data: { inherit after data; };
        };
      };
      ghostty =
        (import ./default.nix {
          inputs.ghostty.packages.${system}.default = config.programs.ghostty.package;
        }).den.aspects.ghostty.homeManager
          args;
    in
    {
      terminal = ghostty.home.sessionVariables.TERMINAL or null;
      enabled = ghostty.programs.ghostty.enable or false;
    };
  macHomebrew =
    (import ../../hosts/torrent/homebrew.nix { inputs = { }; }).den.aspects.torrent.darwin
      {
        config.nix-homebrew.taps = { };
        pkgs.mas = "/test/mas";
      };
  macHome =
    (import ../../hosts/torrent/home.nix {
      inputs.dotfiles-assets = { };
    }).den.aspects.torrent.homeManager
      {
        inherit lib;
        config = { };
        pkgs = { };
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
  testNoDuplicateGhosttyMenu = {
    expr = shared.programs.plasma.configFile.kservicemenurc.Show.RunGhosttyDir or true;
    expected = false;
  };
  testNoDuplicateBuiltinMenu = {
    expr = desktop.configFile.dolphinrc.ContextMenu.ShowOpenTerminal or true;
    expected = false;
  };
  testMenuNames = {
    expr = lib.hasInfix "Actions=OpenInTerminal;\n" menu && lib.hasInfix "Name=Open in Terminal\n" menu;
    expected = true;
  };
  testMenuDirectoryArguments = {
    expr = lib.hasInfix "Exec=ghostty +new-window --working-directory=%f" menu;
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
    expected = null;
  };
  testLinuxEnabled = {
    expr = linux.enabled;
    expected = true;
  };
  testDarwinDisabled = {
    expr = darwin.enabled;
    expected = false;
  };
  testNoMacGhosttyCask = {
    expr = builtins.elem "ghostty" macHomebrew.homebrew.casks;
    expected = false;
  };
  testNoMacGhosttyConfigImport = {
    expr = builtins.any (path: baseNameOf path == "_ghostty.nix") macHome.imports;
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
