{
  lib,
  stdenv,
  esbuild,
}:
stdenv.mkDerivation {
  pname = "claude-code-wakatime-plugin";
  version = "3.1.6";

  src = lib.cleanSource (lib.cleanSourceWith {
    src = ./.;
    filter = name: type:
      !(builtins.elem (baseNameOf name) [
        "node_modules"
        "dist"
        "default.nix"
        ".gitignore"
      ]);
  });

  nativeBuildInputs = [ esbuild ];

  buildPhase = ''
    runHook preBuild
    esbuild src/index.ts --bundle --platform=node --outfile=dist/index.js
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{dist,hooks,scripts}
    cp dist/index.js $out/dist/
    cp hooks/hooks.json $out/hooks/
    cp scripts/run $out/scripts/run
    chmod +x $out/scripts/run
    cp ATTRIBUTIONS.md $out/

    runHook postInstall
  '';

  meta = {
    description = "WakaTime plugin for Claude Code (uses system wakatime-cli)";
    license = lib.licenses.bsd3;
  };
}
