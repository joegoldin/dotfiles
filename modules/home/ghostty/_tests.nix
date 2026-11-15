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
  macGhostty = import ../../hosts/torrent/_ghostty.nix { inherit lib; };
  macGhosttyConfig =
    macGhostty.home.file."Library/Application Support/com.mitchellh.ghostty/config".text;
  linux = evaluate false;
  darwin = evaluate true;
  host = (import ../../hosts/elphael/plasma.nix { inherit lib; }).den.aspects.elphael.homeManager;
  desktop = host.programs.plasma;
  shared = (import ../plasma.nix { inputs = { }; }).den.aspects.plasma.homeManager {
    lib = lib // {
      hm.dag.entryAfter = after: data: { inherit after data; };
    };
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
  testMacGhosttyConfigImport = {
    expr = builtins.any (path: baseNameOf path == "_ghostty.nix") macHome.imports;
    expected = true;
  };
  testMacGhosttySettings = {
    expr = builtins.all (line: builtins.elem line (lib.splitString "\n" macGhosttyConfig)) [
      "font-family = TX02 Nerd Font Mono"
      "font-size = 13"
      "theme = Gruvbox Dark Hard"
      "command = /etc/profiles/per-user/joe/bin/fish"
      "window-subtitle = working-directory"
      "shell-integration-features = sudo,title,ssh-env,ssh-terminfo"
      "mouse-shift-capture = true"
      "keybind = shift+enter=text:\\x1b\\r"
    ];
    expected = true;
  };
  testMacGhosttyConfigOnly = {
    expr =
      builtins.attrNames macGhostty == [ "home" ] && builtins.attrNames macGhostty.home == [ "file" ];
    expected = true;
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
  testPlasmaApplyAfterLinkedGeneration = {
    expr = builtins.elem "linkGeneration" shared.home.activation.applyPlasmaManager.after;
    expected = true;
  };
  testPlasmaApplyAfterConfiguredPlasma = {
    expr = builtins.elem "configure-plasma" shared.home.activation.applyPlasmaManager.after;
    expected = true;
  };
  testPlasmaIconCacheAfterLinkedGeneration = {
    expr = builtins.elem "linkGeneration" shared.home.activation.rebuildKsycoca.after;
    expected = true;
  };
  testPlasmaIconCacheAfterInstalledPackages = {
    expr = builtins.elem "installPackages" shared.home.activation.rebuildKsycoca.after;
    expected = true;
  };
}
