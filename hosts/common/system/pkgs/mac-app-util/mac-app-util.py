#!/usr/bin/env python3
# Python port of hraban/mac-app-util (AGPL-3.0, © Hraban Luyat).
# Ported because the original is Common Lisp and SBCL cannot mmap its dynamic
# space on macOS 27 ("failed to allocate ... at 0x300100000").
#
# Commands (CLI-compatible with the original):
#   mac-app-util mktrampoline FROM.app TO.app
#   mac-app-util sync-dock Foo.app Bar.app ...
#   mac-app-util sync-trampolines /my/nix/Applications "/Applications/My Trampolines"
import os
import plistlib
import shutil
import subprocess
import sys
from pathlib import Path

# Info.plist keys copied from the source app into the trampoline.
# "Based on a hunch, nothing scientific." — upstream
COPYABLE_APP_PROPS = [
    "CFBundleDevelopmentRegion",
    "CFBundleDocumentTypes",
    "CFBundleGetInfoString",
    "CFBundleIconFile",
    "CFBundleIdentifier",
    "CFBundleInfoDictionaryVersion",
    "CFBundleName",
    "CFBundleShortVersionString",
    "CFBundleURLTypes",
    "NSAppleEventsUsageDescription",
    "NSAppleScriptEnabled",
    "NSDesktopFolderUsageDescription",
    "NSDocumentsFolderUsageDescription",
    "NSDownloadsFolderUsageDescription",
    "NSPrincipalClass",
    "NSRemovableVolumesUsageDescription",
    "NSServices",
    "UTExportedTypeDeclarations",
]

DRY_RUN = bool(os.environ.get("DRY_RUN"))


def run(argv, **kwargs):
    if DRY_RUN:
        print(f"exec: {argv}")
        return subprocess.CompletedProcess(argv, 0, stdout="", stderr="")
    if os.environ.get("DEBUGSH"):
        print(f"+ {argv}", file=sys.stderr)
    return subprocess.run(argv, check=True, **kwargs)


def rm_rf(path: Path):
    if DRY_RUN:
        print(f"rm -rf {path}")
        return
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif path.exists() or path.is_symlink():
        path.unlink()


def infoplist(app: Path) -> Path:
    return app / "Contents" / "Info.plist"


def resources(app: Path) -> Path:
    return app / "Contents" / "Resources"


def is_app(path: Path) -> bool:
    return infoplist(path).exists()


def copy_plist_props(src_plist: Path, dst_plist: Path):
    """Copy COPYABLE_APP_PROPS from src into dst, writing dst as XML."""
    if DRY_RUN:
        print(f"merge plist props {src_plist} -> {dst_plist}")
        return
    with open(src_plist, "rb") as f:
        src = plistlib.load(f)
    with open(dst_plist, "rb") as f:
        dst = plistlib.load(f)
    dst.update({k: src[k] for k in COPYABLE_APP_PROPS if k in src})
    # The osacompile applet sets CFBundleIconName ("applet"), which points
    # into its Assets.car and takes precedence over CFBundleIconFile — the
    # trampoline would keep the stock AppleScript icon. Drop it unless the
    # source app defines its own.
    if "CFBundleIconName" not in src:
        dst.pop("CFBundleIconName", None)
    with open(dst_plist, "wb") as f:
        plistlib.dump(dst, f, fmt=plistlib.FMT_XML)


def sync_icons(from_app: Path, to_app: Path):
    """Remove all icons from TO's Resources and copy FROM's over."""
    from_res, to_res = resources(from_app), resources(to_app)
    if not from_res.exists():
        return
    if DRY_RUN:
        print(f"sync icons {from_res} -> {to_res}")
        return
    for icns in to_res.rglob("*.icns"):
        icns.unlink()
    # Also drop the applet's compiled asset catalog — its icon assets would
    # override CFBundleIconFile (see copy_plist_props).
    (to_res / "Assets.car").unlink(missing_ok=True)
    to_res.mkdir(parents=True, exist_ok=True)
    # Top level only, matching upstream rsync --include='*.icns' --exclude='*'.
    for icns in from_res.glob("*.icns"):
        # Follow symlinks: bake the real file into the trampoline.
        shutil.copyfile(icns, to_res / icns.name)


def mktrampoline_app(app: Path, trampoline: Path):
    cmd = f"do shell script \"open '{app}'\""
    run(["/usr/bin/osacompile", "-o", str(trampoline), "-e", cmd])
    sync_icons(app, trampoline)
    copy_plist_props(infoplist(app), infoplist(trampoline))
    # Nudge LaunchServices/Finder to refresh the (sometimes blank) icon.
    run(["/usr/bin/touch", str(trampoline)])


def mktrampoline_bin(binary: Path, trampoline: Path):
    # Both pipes must go to /dev/null or applescript waits on the binary.
    cmd = f"do shell script \"'{binary}' &> /dev/null &\""
    run(["/usr/bin/osacompile", "-o", str(trampoline), "-e", cmd])


def mktrampoline(from_path: str, to_path: str):
    src = Path(from_path).absolute()
    dst = Path(to_path).absolute()
    if not src.exists():
        sys.exit(f"No such file: {from_path}")
    if src.is_dir():
        if not is_app(src):
            sys.exit(f"Path {src} does not appear to be a Mac app (missing Info.plist)")
        mktrampoline_app(src, dst)
    else:
        mktrampoline_bin(src, dst)


def sync_dock(apps):
    """Update persistent dock items whose name matches one of APPS."""
    # dockutil falls back to the original user under sudo; defeat that so it
    # acts as the invoking user (matters in activation scripts).
    os.environ["SUDO_USER"] = ""
    dockutil_args = ["--allhomes"] if os.environ.get("USER") == "root" else []
    try:
        out = run(
            ["dockutil", *dockutil_args, "-L"],
            capture_output=True,
            text=True,
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        print(f"sync-dock: skipping ({e})", file=sys.stderr)
        return
    persistents = [
        line.split("\t")[0]
        for line in out.splitlines()
        if "/nix/store" in line and "persistentApps" in line
    ]
    by_name = {Path(str(a).rstrip("/")).stem: Path(a) for a in apps}
    for existing in persistents:
        app = by_name.get(existing)
        if app is not None:
            run(
                [
                    "dockutil",
                    *dockutil_args,
                    "--add",
                    str(app.resolve()),
                    "--replacing",
                    existing,
                ]
            )


def is_symlinked_dir(d: Path) -> bool:
    return d.is_dir() and d.resolve() != d.absolute()


def gather_apps(src: Path):
    # Some apps nest one directory deeper (e.g. KDE/Foo.app) — search one
    # extra level, same as upstream.
    return sorted([*src.glob("*.app"), *src.glob("*/*.app")])


def sync_trampolines(from_dir: str, to_dir: str):
    src, dst = Path(from_dir).absolute(), Path(to_dir).absolute()
    rm_rf(dst)
    # Since 25.11 nix-darwin copies .app folders directly to /Applications;
    # trampolines only get in the way there. Only act on symlinked dirs.
    if not is_symlinked_dir(src):
        return
    if not DRY_RUN:
        dst.mkdir(parents=True, exist_ok=True)
    apps = gather_apps(src)
    for app in apps:
        mktrampoline_app(app, dst / app.name)
    sync_dock(apps)


USAGE = """Usage:

    mac-app-util mktrampoline FROM.app TO.app
    mac-app-util sync-dock Foo.app Bar.app ...
    mac-app-util sync-trampolines /my/nix/Applications /Applications/MyTrampolines/

mktrampoline creates a "trampoline" application launcher that immediately
launches another application.

sync-dock updates persistent items in your dock if any of the given apps has
the same name.

sync-trampolines syncs an entire directory of *.app files to another by
creating a trampoline launcher for every app, deleting the rest, and updating
the dock.
"""


def main():
    args = sys.argv[1:]
    if "-h" in args or "--help" in args:
        print(USAGE)
        sys.exit(0)
    match args:
        case ["mktrampoline", from_path, to_path]:
            mktrampoline(from_path, to_path)
        case ["sync-dock", *apps] if apps:
            sync_dock([Path(a) for a in apps])
        case ["sync-trampolines", from_dir, to_dir]:
            sync_trampolines(from_dir, to_dir)
        case _:
            print(USAGE)
            sys.exit(1)


if __name__ == "__main__":
    main()
