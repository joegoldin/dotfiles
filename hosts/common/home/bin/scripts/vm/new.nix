{ pkgs, ... }:
{
  name = "new";
  desc = "Create (and optionally start) a new microVM";
  runtimeInputs = with pkgs; [
    jq
    sudo
    nix
    systemd
    glibc
    openssh
  ];
  python-argparse = ''
    import argparse
    import datetime
    import hashlib
    import json
    import os
    import re
    import subprocess
    import sys
    from pathlib import Path

    STATE = Path("/var/lib/microvms")
    SPECS = Path("/var/lib/vm-specs")
    PROFILES = SPECS / "profiles"
    DEFAULT_DOTFILES = Path.home() / "dotfiles"

    # ── ANSI helpers ────────────────────────────────────────────────────────
    R, G, Y, B, BOLD, RST = "\033[31m", "\033[32m", "\033[33m", "\033[34m", "\033[1m", "\033[0m"
    if not sys.stderr.isatty() or os.environ.get("NO_COLOR"):
        R = G = Y = B = BOLD = RST = ""

    def die(msg):
        print(f"{R}error:{RST} {msg}", file=sys.stderr)
        sys.exit(1)

    def info(msg):
        print(f"{B}▸{RST} {msg}", file=sys.stderr)

    def ok(msg):
        print(f"{G}✓{RST} {msg}", file=sys.stderr)

    # ── Parsing ─────────────────────────────────────────────────────────────
    def parse_size_mb(s):
        s = s.strip().upper()
        if s.endswith("G"):
            return int(float(s[:-1]) * 1024)
        if s.endswith("M"):
            return int(s[:-1])
        return int(s)

    def parse_size_gb(s):
        s = s.strip().upper()
        if s.endswith("G"):
            return int(s[:-1])
        if s.endswith("M"):
            return max(1, int(s[:-1]) // 1024)
        return int(s)

    def parse_ttl(s):
        s = s.strip()
        if s.endswith("d"):
            return int(s[:-1])
        if s.endswith("w"):
            return int(s[:-1]) * 7
        return int(s)

    def parse_mount(spec, cwd):
        """SRC[:DST][:ro] -> {src, dst, ro, tag}. '.' means CWD -> /mnt/cwd."""
        if spec == ".":
            src, dst, ro = cwd, "/mnt/cwd", False
        else:
            parts = spec.split(":")
            ro = False
            if parts[-1] in ("ro", "rw"):
                ro = (parts[-1] == "ro")
                parts = parts[:-1]
            src = os.path.abspath(os.path.expanduser(parts[0]))
            dst = parts[1] if len(parts) > 1 else f"/mnt/{os.path.basename(src.rstrip('/')) or 'root'}"
        tag = re.sub(r"[^a-z0-9]", "-", dst.lstrip("/").lower()).strip("-")[:30] or "share"
        return {"src": src, "dst": dst, "ro": ro, "tag": tag}

    # ── CLI ─────────────────────────────────────────────────────────────────
    p = argparse.ArgumentParser(prog="vm new", description="Create a new microVM")
    p.add_argument("name", help="VM name (a-z, 0-9, hyphens; starts with letter)")
    p.add_argument("--profile", default="minimal",
                   help="Profile (desktop/minimal/<custom>); default: minimal")
    p.add_argument("--mount", action="append", default=[], dest="mounts",
                   help="Host dir share: SRC[:DST][:ro] or . for CWD (repeatable)")
    p.add_argument("--pkg", action="append", default=[], dest="pkgs",
                   help="Extra package (repeatable; supports unstable.X prefix)")
    p.add_argument("--ram", help="Memory (e.g. 2G, 1024M)")
    p.add_argument("--cpu", type=int, help="vCPU count")
    p.add_argument("--disk", help="Root disk size (e.g. 16G)")
    p.add_argument("--ttl", help="Days (e.g. 14d, 2w); default 14d")
    p.add_argument("--de", choices=["plasma", "xfce"], help="Override desktop environment")
    p.add_argument("--gui", action="store_true", help="Force-enable SPICE graphics")
    p.add_argument("--resolution", "--res", help="Initial display size, e.g. 1920x1080")
    p.add_argument("--sound", dest="sound", action="store_true", default=None,
                   help="Force-enable audio (SPICE redirect to host viewer)")
    p.add_argument("--no-sound", dest="sound", action="store_false",
                   help="Force-disable audio even if the profile has it on")
    p.add_argument("--start", action="store_true", help="Start VM after creating")
    args = p.parse_args()

    # Name validation
    if not re.match(r"^[a-z][a-z0-9-]{0,30}$", args.name):
        die(f"invalid name: '{args.name}' (must match ^[a-z][a-z0-9-]{{0,30}}$)")
    if (PROFILES / f"{args.name}.json").exists():
        die(f"name '{args.name}' collides with a built-in profile name")

    vm_dir = STATE / args.name
    spec_dir = SPECS / args.name
    if vm_dir.exists() or spec_dir.exists():
        die(f"VM '{args.name}' already exists")

    # Profile resolution
    profile_file = PROFILES / f"{args.profile}.json"
    custom_file = PROFILES / "custom" / f"{args.profile}.json"
    if profile_file.exists():
        profile = json.loads(profile_file.read_text())
    elif custom_file.exists():
        profile = json.loads(custom_file.read_text())
    else:
        die(f"no such profile: {args.profile}")

    # Build meta (also derive deterministic IP so we don't depend on DNS for lookup)
    mac_hash = hashlib.sha1(args.name.encode()).hexdigest()
    mac = "02:" + ":".join(mac_hash[i:i + 2] for i in range(0, 10, 2))
    ip_suffix = (int(mac_hash[10:12], 16) % 240) + 10
    vm_ip = f"10.100.0.{ip_suffix}"

    mounts = [parse_mount(m, os.getcwd()) for m in args.mounts]

    ram_mb = parse_size_mb(args.ram) if args.ram else profile["ram_mb"]
    cpu = args.cpu or profile["cpu"]
    disk_gb = parse_size_gb(args.disk) if args.disk else profile["disk_gb"]
    ttl_days = parse_ttl(args.ttl) if args.ttl else 14
    de = args.de if args.de is not None else profile.get("de")
    gui = args.gui or profile.get("gui", False)

    now = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
    meta = {
        "name": args.name,
        "user": os.environ["USER"],
        "profile": args.profile,
        "profile_base": profile.get("name", args.profile),
        "gui": gui,
        "ram_mb": ram_mb,
        "cpu": cpu,
        "disk_gb": disk_gb,
        "mounts": mounts,
        "extra_pkgs": args.pkgs,
        "de": de,
        "sound": profile.get("sound", False) if args.sound is None else args.sound,
        "resolution": args.resolution or profile.get("resolution", "1920x1080"),
        "hostname": args.name,
        "mac": mac,
        "ip": vm_ip,
        "created_at": now,
        "ttl_days": ttl_days,
        "last_touched": now,
        "paused": False,
        "hypervisor": profile.get("hypervisor", "qemu"),
    }

    dotfiles = Path(os.environ.get("VM_DOTFILES", str(DEFAULT_DOTFILES)))
    if not (dotfiles / "flake.nix").exists():
        die(f"repo checkout not found at {dotfiles} — set VM_DOTFILES")

    user_pub = Path.home() / ".ssh" / "id_ed25519.pub"

    info(f"creating {BOLD}{args.name}{RST} ({profile['description']})")

    # Stage files in a tmp location first, then move to /var/lib/vm-specs/<name>
    # as root. /var/lib/vm-specs is vmusers-writable so moves are cheap.
    tmp = Path(f"/tmp/vm-new-{args.name}-{os.getpid()}")
    tmp.mkdir(parents=True, exist_ok=True)
    (tmp / "meta.json").write_text(json.dumps(meta, indent=2) + "\n")

    gen_cmd = [
        "vm-module-gen",
        "--meta", str(tmp / "meta.json"),
        "--out", str(tmp),
        "--profiles-dir", str(PROFILES),
        "--repo-root", str(dotfiles),
        "--cli-pub", "/var/lib/microvms/ssh/id_ed25519.pub",
    ]
    if user_pub.exists():
        gen_cmd += ["--user-pub", str(user_pub)]
    subprocess.run(gen_cmd, check=True)

    # Move to /var/lib/vm-specs/<name>/ (CLI-owned, NOT /var/lib/microvms/ —
    # microvm.nix manages that itself).
    subprocess.run(["sudo", "mv", str(tmp), str(spec_dir)], check=True)
    subprocess.run(["sudo", "chown", "-R", "root:vmusers", str(spec_dir)], check=True)
    subprocess.run(["sudo", "chmod", "-R", "g+rw", str(spec_dir)], check=True)
    ok(f"staged spec at {spec_dir}")

    # Register with microvm.nix: it'll build the runner, create /var/lib/microvms/<name>/,
    # and store the flake ref. microvm -c fails if the target dir already exists.
    info("registering with microvm.nix")
    try:
        subprocess.run(
            ["sudo", "microvm", "-c", args.name, "-f", f"path:{spec_dir}"],
            check=True,
        )
    except subprocess.CalledProcessError:
        die("microvm -c failed; spec left at " + str(spec_dir) + " for inspection")
    # microvm -c (and its flake evaluation) may have created flake.lock as root:root.
    # Make it group-writable so later vm mount/pkg/update don't need sudo.
    subprocess.run(
        ["sudo", "chown", "-R", "root:vmusers", str(spec_dir)], check=True
    )
    subprocess.run(["sudo", "chmod", "-R", "g+rw", str(spec_dir)], check=True)
    ok("registered")

    # Append to dnsmasq.leases for DHCP static assignment + *.vm DNS.
    # dnsmasq.leases is vmusers-writable; dnsmasq reload goes via polkit.
    lease_line = f"{mac},{vm_ip},{args.name},12h\n"
    with open("/var/lib/microvms/dnsmasq.leases", "a") as f:
        f.write(lease_line)
    subprocess.run(["systemctl", "reload-or-restart", "dnsmasq"], check=True)
    ok(f"lease {vm_ip} ({mac})")

    if args.start:
        info("starting")
        subprocess.run(["systemctl", "start", f"microvm@{args.name}"], check=True)
        # systemctl start returns when ExecStart is invoked, not when the
        # unit is active. Wait until it's active before reporting so `vm gui`
        # below doesn't race.
        import time as _time
        for _ in range(60):
            r = subprocess.run(
                ["systemctl", "is-active", f"microvm@{args.name}"],
                capture_output=True, text=True,
            )
            if r.stdout.strip() == "active":
                break
            _time.sleep(0.5)
        ok(f"running — ssh {args.name}.vm or `vm ssh {args.name}`")
        if gui:
            info("opening SPICE viewer")
            subprocess.run(["vm", "gui", args.name])

    ok(f"done. `vm start {args.name}`" if not args.start else f"`vm ssh {args.name}`")
  '';
}
