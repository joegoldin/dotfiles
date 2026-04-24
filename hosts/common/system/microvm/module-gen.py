#!/usr/bin/env python3
"""Generate module.nix + flake.nix for a microVM from its meta.json + profile.

Pure I/O shape:
  stdin/args -> filesystem writes (module.nix, flake.nix, meta.json mirror)
  deterministic: same inputs produce identical outputs (enabling golden-file tests).

The generated flake.nix references the repo by path (the repo provides
microvm.nix input, common-guest.nix, and fish-guest.nix), and the generated
module.nix imports common-guest.nix, passing meta as a module arg.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def resolve_pkg(name: str) -> str:
    """Translate --pkg form to a nix attr path expression.

    'firefox' -> 'firefox'
    'unstable.wireshark' -> 'unstable.wireshark'
    """
    return name


def render_module(meta: dict, profile: dict) -> str:
    """Emit the module.nix body."""
    all_pkgs = list(profile.get("packages") or []) + list(meta.get("extra_pkgs") or [])
    # Format as a nix list of bare attrs against `pkgs`.
    pkgs_lines = "".join(f"    {resolve_pkg(p)}\n" for p in all_pkgs)

    de = meta.get("de") or profile.get("de")
    gui = bool(meta.get("gui") or profile.get("gui"))

    de_block = render_de(de) if gui else ""
    spice_block = render_spice(meta["name"]) if gui else ""
    autologin_user = (
        meta.get("user")
        if gui and profile.get("services", {}).get("autologin")
        else None
    )
    autologin_block = render_autologin(autologin_user) if autologin_user else ""

    return (
        "{ lib, pkgs, ... }:\n"
        "{\n"
        f'  environment.systemPackages = with pkgs; [\n{pkgs_lines}  ];\n'
        f"{de_block}"
        f"{spice_block}"
        f"{autologin_block}"
        "}\n"
    )


def render_de(de: str | None) -> str:
    if de == "plasma":
        return (
            "\n  # Desktop environment: KDE Plasma 6\n"
            "  services.xserver.enable = true;\n"
            "  services.displayManager.sddm.enable = true;\n"
            "  services.displayManager.sddm.wayland.enable = true;\n"
            "  services.desktopManager.plasma6.enable = true;\n"
        )
    if de == "xfce":
        return (
            "\n  # Desktop environment: XFCE (lightweight)\n"
            "  services.xserver.enable = true;\n"
            "  services.xserver.displayManager.lightdm.enable = true;\n"
            "  services.xserver.desktopManager.xfce.enable = true;\n"
        )
    return ""


def render_spice(name: str) -> str:
    # SPICE UNIX socket at /var/lib/microvms/<name>/spice.sock plus vdagent
    # channel for clipboard/resize.
    #
    # microvm.nix's optimize.enable=true rewrites qemu into a stripped
    # test-only variant that lacks SPICE. graphics.enable=true keeps the
    # full qemu but also adds -display gtk,gl=on (no good for SPICE).
    # optimize.enable=false is the sweet spot: full qemu, no GTK display.
    # We supply our own SPICE display via -spice + virtio-vga.
    return (
        "\n  # SPICE graphics (socket consumed by `vm gui`)\n"
        "  services.spice-vdagentd.enable = true;\n"
        "  microvm.optimize.enable = false;\n"
        "  # `microvm` machine type doesn't do legacy VGA — use virtio-gpu-pci.\n"
        "  # usb-tablet gives an absolute pointer so the viewer doesn't\n"
        "  # capture the mouse; usb-kbd avoids the PS/2 fallback.\n"
        "  microvm.qemu.extraArgs = [\n"
        '    "-device" "virtio-gpu-pci"\n'
        '    "-device" "qemu-xhci"\n'
        '    "-device" "usb-tablet"\n'
        '    "-device" "usb-kbd"\n'
        f'    "-spice" "unix=on,addr=/var/lib/microvms/{name}/spice.sock,disable-ticketing=on"\n'
        '    "-device" "virtio-serial-pci"\n'
        '    "-chardev" "spicevmc,id=spicechannel0,name=vdagent"\n'
        '    "-device" "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"\n'
        "  ];\n"
    )


def render_autologin(user: str) -> str:
    return (
        "\n  # Autologin for SPICE session\n"
        f'  services.displayManager.autoLogin = {{ enable = true; user = "{user}"; }};\n'
    )


def nix_str(s: str) -> str:
    """Nix-quote a string (double-quoted, minimal escaping)."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def render_flake(meta: dict, repo_root: Path, cli_pub: str, user_pub: str) -> str:
    name = meta["name"]
    return (
        "{\n"
        f'  description = "microVM: {name}";\n'
        "\n"
        "  inputs = {\n"
        f'    dotfiles.url = "git+file://{repo_root}";\n'
        '    nixpkgs.follows = "dotfiles/nixpkgs";\n'
        '    microvm-nix.follows = "dotfiles/microvm-nix";\n'
        '    home-manager.follows = "dotfiles/home-manager";\n'
        "  };\n"
        "\n"
        "  outputs = { self, nixpkgs, microvm-nix, home-manager, dotfiles, ... }: let\n"
        '    system = "x86_64-linux";\n'
        "    pkgs = import nixpkgs {\n"
        "      inherit system;\n"
        "      config.allowUnfree = true;\n"
        "      overlays = builtins.attrValues dotfiles.overlays;\n"
        "    };\n"
        "    meta = builtins.fromJSON (builtins.readFile ./meta.json);\n"
        f"    cliSshPubKey = {nix_str(cli_pub)};\n"
        f"    userSshPubKey = {nix_str(user_pub)};\n"
        "  in {\n"
        f"    nixosConfigurations.{name} = nixpkgs.lib.nixosSystem {{\n"
        "      inherit system pkgs;\n"
        "      specialArgs = {\n"
        "        inherit meta cliSshPubKey userSshPubKey;\n"
        f'        fishGuest = dotfiles + "/hosts/common/home/fish-guest.nix";\n'
        "      };\n"
        "      modules = [\n"
        "        microvm-nix.nixosModules.microvm\n"
        "        home-manager.nixosModules.home-manager\n"
        f'        (dotfiles + "/hosts/common/system/microvm/common-guest.nix")\n'
        "        ./module.nix\n"
        "      ];\n"
        "    };\n"
        "  };\n"
        "}\n"
    )


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--meta", required=True, type=Path, help="Path to meta.json")
    p.add_argument("--out", required=True, type=Path, help="Output directory")
    p.add_argument(
        "--profiles-dir",
        required=True,
        type=Path,
        help="Directory containing <profile>.json files",
    )
    p.add_argument(
        "--repo-root",
        required=True,
        type=Path,
        help="Path to the dotfiles repo root (referenced by the generated flake)",
    )
    p.add_argument(
        "--cli-pub",
        required=True,
        type=Path,
        help="Path to CLI ed25519 public key (contents baked into flake.nix)",
    )
    p.add_argument(
        "--user-pub",
        type=Path,
        default=None,
        help="Path to user's personal ed25519 public key (optional)",
    )
    args = p.parse_args()

    meta = json.loads(args.meta.read_text())
    base = meta["profile_base"]
    profile_path = args.profiles_dir / f"{base}.json"
    if not profile_path.exists():
        profile_path = args.profiles_dir / "custom" / f"{base}.json"
    if not profile_path.exists():
        sys.exit(f"no such profile: {base}")
    profile = json.loads(profile_path.read_text())

    cli_pub = args.cli_pub.read_text().strip()
    user_pub = args.user_pub.read_text().strip() if (args.user_pub and args.user_pub.exists()) else ""

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "module.nix").write_text(render_module(meta, profile))
    (args.out / "flake.nix").write_text(render_flake(meta, args.repo_root, cli_pub, user_pub))
    # Mirror meta.json into the VM dir so the flake can readFile it.
    (args.out / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")


if __name__ == "__main__":
    main()
