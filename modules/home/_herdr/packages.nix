{ inputs, pkgs }:
let
  inherit (pkgs) lib;
  system = pkgs.stdenv.hostPlatform.system;
  toml = pkgs.formats.toml { };
  runtimePath = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.jq
    pkgs.curl
    pkgs.git
    pkgs.openssh
    pkgs.ripgrep
  ];
  ttt = inputs.ttt.packages.${system}.default.overrideAttrs (_: {
    version = "1.7.1";
    # Upstream uses the commit abbreviation even when built from a release tag.
    __intentionallyOverridingVersion = true;
    ldflags = [
      "-s"
      "-w"
      "-X main.version=1.7.1"
    ];
  });
  autoTitle = pkgs.buildGoModule {
    pname = "herdr-auto-title";
    version = "0.13.0";
    src = inputs.herdr-auto-title;
    vendorHash = "sha256-QxFp1b7pf7bn3Hh0hyaj8ke5Z61N+WwjhHt3pFiapTs=";
    subPackages = [ "cmd/herdr-auto-title" ];
    checkPhase = ''
      runHook preCheck
      go test ./...
      runHook postCheck
    '';
    meta = {
      description = "Local contextual tab and pane titles for Herdr";
      license = lib.licenses.mit;
      mainProgram = "herdr-auto-title";
    };
  };
  navigator = pkgs.rustPlatform.buildRustPackage {
    pname = "herdr-navigator";
    version = "0.3.6";
    src = inputs.herdr-navigator;
    cargoLock.lockFile = "${inputs.herdr-navigator}/Cargo.lock";
    # These test fixtures compare canonical paths; /tmp is a symlink on Darwin.
    postPatch = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      substituteInPlace src/app.rs src/sources.rs \
        --replace-fail '"/tmp"' '"/private/tmp"'
    '';
    meta = {
      description = "Fuzzy workspace and pane navigator for Herdr";
      license = lib.licenses.mit;
      mainProgram = "herdr-navigator";
    };
  };
  manifest = source: builtins.fromTOML (builtins.readFile "${source}/herdr-plugin.toml");
  plugin =
    name: source: settings: install:
    pkgs.runCommand name { } ''
      mkdir -p $out
      cp ${toml.generate "herdr-plugin.toml" settings} $out/herdr-plugin.toml
      cp ${source}/LICENSE $out/LICENSE
      ${install}
    '';
  titleManifest = manifest inputs.herdr-auto-title;
  navManifest = manifest inputs.herdr-navigator;
  tttManifest = manifest "${inputs.ttt}/herdr-plugin";
  tttLauncher = pkgs.writeShellScript "ttt-herdr-open-worktree" ''
    export PATH="${runtimePath}:$PATH"
    ${lib.replaceStrings [ "exec ttt" ] [ "exec ${ttt}/bin/ttt" ] (
      builtins.readFile "${inputs.ttt}/herdr-plugin/scripts/open-worktree.sh"
    )}
  '';
in
{
  inherit ttt;
  herdr-auto-title = autoTitle;
  herdr-navigator = navigator;

  herdr-auto-title-plugin = plugin "herdr-auto-title-plugin" inputs.herdr-auto-title (
    titleManifest
    // {
      build = [ ];
      platforms = [
        "linux"
        "macos"
      ];
      startup = [ { command = [ "${autoTitle}/bin/herdr-auto-title" ]; } ];
      actions = map (
        entry:
        entry
        // {
          command = [
            "${autoTitle}/bin/herdr-auto-title"
            "restart"
          ];
        }
      ) titleManifest.actions;
    }
  ) "";

  herdr-navigator-plugin = plugin "herdr-navigator-plugin" inputs.herdr-navigator (
    navManifest
    // {
      build = [ ];
      actions = map (
        entry: entry // { command = [ "${navigator}/bin/herdr-navigator" ] ++ builtins.tail entry.command; }
      ) navManifest.actions;
      panes = map (
        entry: entry // { command = [ "${navigator}/bin/herdr-navigator" ] ++ builtins.tail entry.command; }
      ) navManifest.panes;
    }
  ) "";

  herdr-ttt-plugin = plugin "herdr-ttt-plugin" inputs.ttt (
    tttManifest
    // {
      build = [ ];
      actions = map (entry: entry // { command = [ "${tttLauncher}" ]; }) tttManifest.actions;
      panes = map (entry: entry // { command = [ "${tttLauncher}" ]; }) tttManifest.panes;
    }
  ) "";
}
