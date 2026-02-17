{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  fetchNpmDeps,
  npmHooks,
  nodejs,
  _7zz,
  icoutils,
  imagemagick,
  wget,
  dpkg,
  electron_37,
  makeWrapper,
  wrapGAppsHook3,
  gtk3,
  copyDesktopItems,
  makeDesktopItem,
  python3,
  pkg-config,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "1.3.11";
  claudeVersion = "1.1.3189";

  src = fetchFromGitHub {
    owner = "aaddrick";
    repo = "claude-desktop-debian";
    rev = "3c816a9af9a286bd6c8df0177cba973cdf380cfb";
    hash = "sha256-3texCB0TftzDDXAWGKyaCkGgLnzVXPBO5R0iU3m4/0Q=";
  };

  claudeExe = fetchurl {
    url = "https://downloads.claude.ai/releases/win32/x64/${finalAttrs.claudeVersion}/Claude-1b7b58b8b5060b7d5d19c6863d8f0caef4f0fc97.exe";
    hash = "sha256-rxpkejLUpWzR89Ph/DMb2I3WjTEmC8KkOBRP+hWK0W4=";
  };

  npmDeps = fetchNpmDeps {
    src = ./claude-desktop-npm;
    hash = "sha256-SP1sqDbiUtzN4EIPcKkHglBe9eFlBMTnH5/ijhzs8Fk=";
  };

  nativeBuildInputs = [
    npmHooks.npmConfigHook
    nodejs
    _7zz
    icoutils
    imagemagick
    wget
    dpkg
    python3
    pkg-config
    makeWrapper
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
  ];

  # We handle wrapping ourselves via makeWrapper + gappsWrapperArgs
  dontWrapGApps = true;

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    npm_config_offline = "true";
    npm_config_nodedir = "${nodejs}";
  };

  postUnpack = ''
    cp ${./claude-desktop-npm/package.json} source/package.json
    cp ${./claude-desktop-npm/package-lock.json} source/package-lock.json
  '';

  postPatch = ''
    # Create shims and wrappers for the Nix sandbox
    mkdir -p .fake-bin

    # 7z wrapper (nixpkgs provides 7zz, script expects 7z)
    cat > .fake-bin/7z <<SEVENZ
    #!/bin/sh
    exec ${_7zz}/bin/7zz "\$@"
    SEVENZ
    chmod +x .fake-bin/7z

    # No-op wrappers for package managers
    for cmd in apt apt-get dnf yum; do
      cat > .fake-bin/$cmd <<'FAKECMD'
    #!/bin/sh
    exit 0
    FAKECMD
      chmod +x .fake-bin/$cmd
    done

    # Fake getent for sandbox (no passwd db)
    cat > .fake-bin/getent <<'FAKECMD'
    #!/bin/sh
    echo "nixbld:x:1000:1000:Nix Build User:$HOME:/bin/bash"
    FAKECMD
    chmod +x .fake-bin/getent

    # Fix shebangs in sub-scripts (sandbox has no /usr/bin/env)
    patchShebangs scripts/

    # Patch node-pty install to use pre-compiled copy from source root
    substituteInPlace build.sh \
      --replace-fail \
        'npm install node-pty 2>&1' \
        'mkdir -p node_modules && cp -r "$project_root/node_modules/node-pty" node_modules/ && cp -r "$project_root/node_modules/nan" node_modules/ 2>&1'

    # Patch setup_work_directory to pre-populate node_modules after creating build/.
    # The function does rm -rf $work_dir, so we inject our copy right after mkdir.
    substituteInPlace build.sh \
      --replace-fail \
        'mkdir -p "$app_staging_dir" || exit 1' \
        'mkdir -p "$app_staging_dir" || exit 1
      # Nix: pre-populate node_modules from source root + nixpkgs electron
      cp -r "$project_root/node_modules" "$work_dir/node_modules"
      chmod -R u+w "$work_dir/node_modules"
      mkdir -p "$work_dir/node_modules/electron/dist"
      cp -rL ${electron_37}/libexec/electron/. "$work_dir/node_modules/electron/dist/"
      chmod -R u+w "$work_dir/node_modules/electron/dist"'
  '';

  buildPhase = ''
    runHook preBuild
    export HOME=$(mktemp -d)
    export PATH="$(pwd)/.fake-bin:$PATH"

    bash build.sh --exe "$claudeExe" --build deb --clean no
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # Extract the built deb
    debFile=$(find . -name '*.deb' -print -quit)
    mkdir -p $TMPDIR/deb-extract
    dpkg-deb -x "$debFile" $TMPDIR/deb-extract

    # Install the full app tree from the deb so electron resolves resources correctly.
    # The bundled electron is already from nixpkgs (copied during build) so rpaths are fine.
    mkdir -p $out/lib
    cp -r $TMPDIR/deb-extract/usr/lib/claude-desktop $out/lib/claude-desktop

    # Install icons
    if [ -d $TMPDIR/deb-extract/usr/share/icons ]; then
      mkdir -p $out/share
      cp -r $TMPDIR/deb-extract/usr/share/icons $out/share/
    fi

    # Create launcher wrapper with GTK/GLib env vars (via wrapGAppsHook3) and
    # --no-sandbox (NixOS lacks the setuid chrome-sandbox helper).
    mkdir -p $out/bin
    makeWrapper $out/lib/claude-desktop/node_modules/electron/dist/electron $out/bin/claude-desktop \
      "''${gappsWrapperArgs[@]}" \
      --add-flags "$out/lib/claude-desktop/node_modules/electron/dist/resources/app.asar" \
      --add-flags "--disable-features=CustomTitlebar" \
      --add-flags "--no-sandbox" \
      --set ELECTRON_FORCE_IS_PACKAGED "true" \
      --set ELECTRON_USE_SYSTEM_TITLE_BAR "1"

    runHook postInstall
  '';

  # Don't strip or patch ELF binaries — the bundled electron is already
  # properly linked from nixpkgs and re-processing it causes SIGILL.
  dontStrip = true;
  dontPatchELF = true;

  desktopItems = [
    (makeDesktopItem {
      name = "claude-desktop";
      exec = "claude-desktop %u";
      icon = "claude-desktop";
      desktopName = "Claude";
      comment = "Claude Desktop for Linux";
      categories = [
        "Office"
        "Utility"
      ];
      mimeTypes = ["x-scheme-handler/claude"];
      startupWMClass = "Claude";
    })
  ];

  meta = {
    description = "Claude Desktop for Linux";
    homepage = "https://github.com/aaddrick/claude-desktop-debian";
    license = with lib.licenses; [mit asl20];
    platforms = ["x86_64-linux"];
    mainProgram = "claude-desktop";
  };
})
