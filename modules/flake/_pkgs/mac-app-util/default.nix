{
  lib,
  stdenvNoCC,
  python3,
  makeWrapper,
  dockutil,
}:
# Python port of hraban/mac-app-util: Spotlight/Launchpad trampolines and
# dock sync for Nix-installed .app bundles. Ported off Common Lisp because
# SBCL cannot mmap its dynamic space on macOS 27. CLI-compatible with the
# original (mktrampoline / sync-dock / sync-trampolines).
stdenvNoCC.mkDerivation {
  pname = "mac-app-util";
  version = "1.0.2-py";

  src = ./mac-app-util.py;
  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm644 "$src" "$out/libexec/mac-app-util.py"
    makeWrapper "${python3}/bin/python3" "$out/bin/mac-app-util" \
      --add-flags "$out/libexec/mac-app-util.py" \
      --suffix PATH : "${lib.makeBinPath [ dockutil ]}"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/mac-app-util --help >/dev/null
  '';

  meta = {
    description = "Manage Mac app launchers for Nix-installed apps (Python port of hraban/mac-app-util)";
    homepage = "https://github.com/hraban/mac-app-util";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.darwin;
    mainProgram = "mac-app-util";
  };
}
