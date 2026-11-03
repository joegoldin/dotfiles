{
  lib,
  stdenv,
  swift,
  sqlite,
  python3,
  makeWrapper,
  electron,
  android-tools,
  fetchurl,
  source,
}:
let
  manifest = lib.importJSON "${source}/mac/package.json";
  ws = fetchurl {
    url = "https://registry.npmjs.org/ws/-/ws-8.22.0.tgz";
    hash = "sha512-Ydggc987+RO0AnWtZ/7Wq9FtNvcrL1b/RO0ud9mWjUPgDrsAAwQSF51sm2hm1XofbU/4jkpGEsLFsZZxU+1DOg==";
  };
in
stdenv.mkDerivation {
  pname = "twindesk";
  version = "${manifest.version}-unstable-${source.shortRev}";
  src = source;

  nativeBuildInputs = [
    swift
    python3
    makeWrapper
  ];
  buildInputs = [ sqlite ];
  dontConfigure = true;
  postPatch = ''
    # Nix's SDK declares SQLite3 but removes its headers. Use a distinct module
    # backed by Nix SQLite so Swift does not load the SDK's broken module map.
    mkdir -p sqlite-module
    cat > sqlite-module/module.modulemap <<EOF
    module TwinDeskSQLite3 [system] {
      header "${lib.getDev sqlite}/include/sqlite3.h"
      link "sqlite3"
      export *
    }
    EOF
    substituteInPlace mac-helper/Sources/macshare-helper/Notifs.swift \
      --replace-fail 'import SQLite3' 'import TwinDeskSQLite3'
    substituteInPlace mac-helper/build.sh \
      --replace-fail 'swiftc -O' 'swiftc -I "$TWINDESK_SQLITE_MODULE" -O'
  '';
  # Repack Nix's Electron, not upstream's npm/electron-packager download pipeline.
  buildPhase = ''
    runHook preBuild
    export TWINDESK_SQLITE_MODULE="$PWD/sqlite-module"
    sh mac-helper/build.sh ${if stdenv.hostPlatform.isAarch64 then "arm64" else "x64"}
    runHook postBuild
  '';
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    printf 'import TwinDeskSQLite3\nprint(String(cString: sqlite3_libversion()))\n' > sqlite-module/check.swift
    swiftc -I sqlite-module sqlite-module/check.swift -o sqlite-module/check
    sqlite-module/check
    runHook postCheck
  '';
  installPhase = ''
    runHook preInstall
    app="$out/Applications/TwinDesk.app"
    mkdir -p "$out/Applications" "$out/bin"
    cp -R ${electron}/Applications/Electron.app "$app"
    chmod -R u+w "$app"
    resources="$app/Contents/Resources"
    rm -f "$resources/default_app.asar"
    mkdir -p "$resources/app/mac-helper/.build/release" "$resources/app/node_modules/ws"
    cp -R mac shared "$resources/app/"
    cp mac-helper/.build/release/* "$resources/app/mac-helper/.build/release/"
    tar -xf ${ws} -C "$resources/app/node_modules/ws" --strip-components=1
    mkdir -p "$resources/app/mac/vendor/adb"
    # Signed app resources cannot contain symlinks outside the bundle.
    cp ${android-tools}/bin/adb "$resources/app/mac/vendor/adb/adb"
    cp shared/icon/teindesk-dark.icns "$resources/twindesk.icns"
    export app
    python3 - <<'PY'
    import json, os, pathlib, plistlib, re
    app = pathlib.Path(os.environ['app'])
    resources = app / 'Contents/Resources'
    manifest = json.loads(pathlib.Path('mac/package.json').read_text())
    manifest['main'] = 'mac/main.js'
    (resources / 'app/package.json').write_text(json.dumps(manifest))
    info = app / 'Contents/Info.plist'
    data = plistlib.loads(info.read_bytes())
    # Keep upstream's permission descriptions and URL registration in sync with main.
    script = pathlib.Path('mac/build-app.sh').read_text()
    extra = re.search(r"cat > dist/extra\.plist <<'EOF'\n(.*?)\nEOF", script, re.S)
    if extra is None:
        raise RuntimeError('upstream extra.plist layout changed')
    data.update(plistlib.loads(extra[1].encode()))
    data.update(CFBundleIdentifier='org.macshare.mac', CFBundleName='TwinDesk',
                CFBundleDisplayName='TwinDesk', CFBundleIconFile='twindesk.icns',
                CFBundleShortVersionString=manifest['version'], CFBundleVersion=manifest['version'])
    info.write_bytes(plistlib.dumps(data))
    PY
    makeWrapper "$app/Contents/MacOS/Electron" "$out/bin/twindesk" --run 'umask 077'
    runHook postInstall
  '';

  # Re-sign the modified Electron bundle; macOS still requires you to grant permissions.
  postFixup = ''
    /usr/bin/codesign --force --deep --sign - \
      --entitlements mac/entitlements.plist "$out/Applications/TwinDesk.app"
    /usr/bin/codesign --verify --deep --strict "$out/Applications/TwinDesk.app"
  '';
  meta = {
    description = "Share screens, input, clipboard and files between your devices";
    homepage = "https://github.com/InukaAsith/TwinDesk";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.darwin;
    mainProgram = "twindesk";
  };
}
