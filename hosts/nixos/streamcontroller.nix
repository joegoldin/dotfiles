{ pkgs }:
(pkgs.unstable.streamcontroller.override { isKde = true; }).overrideAttrs (old: {
  version = "1.5.0-unstable-2025-02-19";
  src = pkgs.fetchFromGitHub {
    owner = "StreamController";
    repo = "StreamController";
    rev = "d06db54a6cd8db3b62f3db2c66612e85c8498ca4";
    hash = "sha256-mkGlBvFOIWJfjoiB9DHlISL4W/0HE/NGuYerEsiJWV0=";
  };
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
  postFixup = (old.postFixup or "") + ''
    wrapProgram $out/bin/streamcontroller \
      --set GSK_RENDERER ngl
  '';
})
