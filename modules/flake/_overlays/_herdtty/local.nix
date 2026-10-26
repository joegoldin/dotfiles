{
  lib,
  nix,
  python3,
  symlinkJoin,
  writeShellScriptBin,
  source,
  signingIdentity,
}:
let
  revision = source.rev or (throw "herdtty local builds require a pinned source revision");
in
symlinkJoin {
  name = "herdtty-local";
  paths = [
    (writeShellScriptBin "herdtty-build-local" ''
      exec ${python3}/bin/python3 ${./build-local.py} \
        --source ${source} --revision ${lib.escapeShellArg revision} --nix ${nix}/bin/nix \
        --identity ${lib.escapeShellArg signingIdentity} "$@"
    '')
    (writeShellScriptBin "herdtty" ''
      exec "$HOME/Applications/herdtty.app/Contents/MacOS/herdtty" "$@"
    '')
    (writeShellScriptBin "herdtty-terminal" ''
      exec "$HOME/Applications/herdtty Terminal.app/Contents/MacOS/herdtty" "$@"
    '')
  ];
  passthru = {
    localSource = source;
    localSourceRevision = revision;
  };
  meta = {
    description = "Local Xcode source build and signed herdtty launchers";
    platforms = lib.platforms.darwin;
    mainProgram = "herdtty";
  };
}
