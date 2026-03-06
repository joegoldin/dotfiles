{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_9,
  pnpmConfigHook,
  python3,
  makeWrapper,
}:

let
  pname = "yepanywhere-relay";
  version = "0.4.8";

  src = fetchFromGitHub {
    owner = "kzahel";
    repo = "yepanywhere";
    rev = "v${version}";
    hash = "sha256-QlRsUB9jq2p7mSGXInk7sRJpr+/rg+lu83XichTVLBY=";
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [
    nodejs
    pnpm_9
    pnpmConfigHook
    python3 # needed by node-gyp for better-sqlite3
    makeWrapper
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit pname version src;
    pnpm = pnpm_9;
    hash = "sha256-B9dRKYJ3fm9+GbDtEdkH9SNeptxg5RdEOcp8ibNyBNs=";
    fetcherVersion = 3;
  };

  buildPhase = ''
    runHook preBuild
    pnpm --filter @yep-anywhere/shared build
    pnpm --filter @yep-anywhere/relay build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/yepanywhere-relay $out/bin

    # Copy full monorepo layout so pnpm workspace symlinks resolve
    cp -r packages $out/lib/yepanywhere-relay/
    cp -r node_modules $out/lib/yepanywhere-relay/
    cp package.json $out/lib/yepanywhere-relay/

    makeWrapper ${nodejs}/bin/node $out/bin/yepanywhere-relay \
      --add-flags "$out/lib/yepanywhere-relay/packages/relay/dist/index.js" \
      --set NODE_ENV production

    runHook postInstall
  '';

  meta = {
    description = "Relay server for yepanywhere - routes encrypted WebSocket traffic";
    homepage = "https://github.com/kzahel/yepanywhere";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "yepanywhere-relay";
  };
}
