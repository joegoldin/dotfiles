{
  lib,
  stdenv,
  fetchFromGitHub,
  zig,
  git,
}:
stdenv.mkDerivation rec {
  pname = "git-hunk";
  version = "0.10.2";

  src = fetchFromGitHub {
    owner = "shhac";
    repo = "git-hunk";
    tag = "v${version}";
    hash = "sha256-Qqgn2ODRkxxlqTp6Ymg1XIRKotuqt/UXsjgcmpym1tw=";
  };

  nativeBuildInputs = [ zig ];

  # Zig needs a writable global cache directory
  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
  '';

  buildPhase = ''
    runHook preBuild
    zig build -Doptimize=ReleaseFast --color off
    runHook postBuild
  '';

  # Zig uses git at build time for version info
  nativeCheckInputs = [ git ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp zig-out/bin/git-hunk $out/bin/git-hunk
    runHook postInstall
  '';

  meta = with lib; {
    description = "Non-interactive, deterministic git hunk staging using content hashes";
    homepage = "https://github.com/shhac/git-hunk";
    license = licenses.mit;
    mainProgram = "git-hunk";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
