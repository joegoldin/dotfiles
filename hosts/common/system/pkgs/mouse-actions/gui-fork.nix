# Mouse Actions config editor (Tauri v2 GUI) built from
# github.com/joegoldin/mouse-actions @ configurable-input-rules.
#
# Replaces the upstream AppImage path (`mouse-actions-gui-appimage.nix`)
# which is pinned to the unforked 0.4.5 and doesn't know about the new
# `modifier_remaps` / `chord_bindings` config fields.
{
  lib,
  cargo-tauri,
  fetchFromGitHub,
  fetchNpmDeps,
  glib-networking,
  libsoup_3,
  libxtst,
  libxi,
  libX11,
  libevdev,
  nodejs,
  npmHooks,
  openssl,
  pkg-config,
  rustPlatform,
  webkitgtk_4_1,
  wrapGAppsHook4,
}:
rustPlatform.buildRustPackage rec {
  pname = "mouse-actions-gui-fork";
  version = "0.4.5-configurable";

  src = fetchFromGitHub {
    owner = "joegoldin";
    repo = "mouse-actions";
    rev = "95ef2aa";
    hash = "sha256-UMxVd739cUrxBvRSn9EkZ0+77Vu8/xuFhgRJmrHCRCQ=";
  };

  npmRoot = "config-editor";
  npmDeps = fetchNpmDeps {
    name = "mouse-actions-gui-npm-deps";
    inherit src;
    sourceRoot = "${src.name}/config-editor";
    hash = "sha256-T3m1OEobHP2+ac528nDWUtcaFIOT9p6gbFmOqmbxyBE=";
  };

  cargoRoot = "config-editor/src-tauri";
  buildAndTestSubdir = cargoRoot;
  cargoHash = "sha256-rHTVNGD3vAzY19dbz5bE1WNHNPfjl8txbKWomGLxnRk=";

  # `npm install` against the lockfile requires this because the storybook
  # devDeps have a peer-dep mismatch upstream (storybook 7.x vs vite plugin
  # 9.x). They don't affect the production build.
  env.NPM_CONFIG_LEGACY_PEER_DEPS = "true";
  env.OPENSSL_NO_VENDOR = "1";

  # Cargo emits `mouse_actions_config_editor` (the [bin] name from
  # src-tauri/Cargo.toml). Existing consumers (the tray's
  # `shutil.which("mouse-actions-gui")`, the home-manager packages list, the
  # CLI's `mouse-actions show-gui`) expect the AppImage binary name.
  postInstall = ''
    ln -s mouse_actions_config_editor $out/bin/mouse-actions-gui
  '';

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs
    npmHooks.npmConfigHook
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    glib-networking
    libsoup_3
    libxtst
    libxi
    libX11
    libevdev
    openssl
    webkitgtk_4_1
  ];

  meta = {
    description = "Mouse Actions Tauri GUI (joegoldin fork with modifier_remaps + chord_bindings)";
    homepage = "https://github.com/joegoldin/mouse-actions";
    license = lib.licenses.mit;
    mainProgram = "mouse-actions-gui";
    platforms = lib.platforms.linux;
  };
}
