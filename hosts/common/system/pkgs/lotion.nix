{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  electron,
  makeWrapper,
  python3,
  pkg-config,
  jq,
  alsa-lib,
  copyDesktopItems,
  makeDesktopItem,
}:
buildNpmPackage rec {
  pname = "lotion";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "puneetsl";
    repo = "lotion";
    tag = "v${version}";
    hash = "sha256-oOpcIIdKT303a9qOZ50To67XEQ/4olWFJr1Sy3rv2kg=";
  };

  npmDepsHash = "sha256-sZSsKLKGDRB1uCJrLUE23j6Qi+B13YP6OP2j0ZE6+V8=";

  nativeBuildInputs = [
    makeWrapper
    python3
    pkg-config
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
  ];

  patches = [
    ./lotion-open-in-tab.patch
  ];

  makeCacheWritable = true;

  # No build script in package.json; source is plain JS
  dontNpmBuild = true;

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
  };

  # package.json "files" field is too restrictive (only *.js, *.html at root).
  # Patch it to include the full source tree needed at runtime.
  postPatch = ''
    ${lib.getExe jq} '.files = ["src", "assets", "config", "i18n", "*.js", "*.html"]' \
      package.json > package.json.tmp && mv package.json.tmp package.json
  '';

  postInstall = ''
    makeWrapper ${electron}/bin/electron $out/bin/lotion \
      --add-flags $out/lib/node_modules/lotion/src/main/index.js

    install -Dm644 $out/lib/node_modules/lotion/assets/icon.png \
      $out/share/icons/hicolor/512x512/apps/lotion.png
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "lotion";
      exec = "lotion %U";
      icon = "lotion";
      desktopName = "Lotion";
      comment = "Unofficial Notion.so Desktop App for Linux";
      categories = [
        "Office"
        "TextEditor"
      ];
    })
  ];

  meta = with lib; {
    description = "Unofficial Notion.so Desktop App for Linux";
    homepage = "https://github.com/puneetsl/lotion";
    license = licenses.mit;
    mainProgram = "lotion";
    platforms = platforms.linux;
  };
}
