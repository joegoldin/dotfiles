{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs,
  pnpm_9,
  pnpmConfigHook,
}:

let
  pname = "yepanywhere-remote";
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

    # Build remote client with /remote/ base path so asset URLs are correct
    pushd packages/client
    pnpm exec tsc
    pnpm exec vite build --config vite.config.remote.ts --base /remote/
    popd

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r packages/client/dist-remote $out
    runHook postInstall
  '';

  meta = {
    description = "YepAnywhere remote client - standalone static web UI";
    homepage = "https://github.com/kzahel/yepanywhere";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
}
