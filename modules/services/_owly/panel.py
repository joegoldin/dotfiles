"""User-session command adapter for the Owly Share plasmoid."""

import argparse
import ipaddress
import json
import os
from pathlib import Path
import re
import socket
import subprocess

OWLY = "@owly@"
SYSTEMCTL = "@systemctl@"
BUSCTL = "@busctl@"
UNIT = "owly-receive.service"
BUS = "io.github.t4t5.Owly"
IFACE = BUS + ".Radio1"
MAC = re.compile(r"(?:[0-9a-f]{2}:){5}[0-9a-f]{2}", re.I)
RECEIVER = re.compile(r'(\S+)\s+(".*")\s+\(\[([^]]+)\]:\d+\)')


def radio_property(name, fallback):
    result = subprocess.run(
        [
            BUSCTL,
            "--system",
            "--auto-start=no",
            "--timeout=2s",
            "--json=short",
            "get-property",
            BUS,
            "/io/github/t4t5/Owly",
            IFACE,
            name,
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode:
        return fallback
    try:
        return json.loads(result.stdout)["data"]
    except (ValueError, KeyError):
        return fallback


def unit(*args):
    return subprocess.run([SYSTEMCTL, "--user", *args, UNIT], check=False).returncode


def status():
    return {
        "radio": radio_property("State", "unavailable"),
        "visible": not unit("is-active", "--quiet"),
        "dir": (Path.home() / "Downloads").as_uri(),
        "name": socket.gethostname(),
    }


def link_local(mac):
    eui = bytearray.fromhex(mac.replace(":", ""))
    eui[0] ^= 2
    eui[3:3] = b"\xff\xfe"
    return ipaddress.IPv6Address(b"\xfe\x80" + bytes(6) + eui)


def devices(lines, peers):
    by_addr = {}
    for peer in peers:
        mac = peer.get("mac", {}).get("data", "")
        if MAC.fullmatch(mac):
            by_addr[link_local(mac)] = {
                "mac": mac,
                "rssi": peer.get("rssi", {}).get("data"),
            }
    found = []
    for line in lines:
        match = RECEIVER.fullmatch(line)
        if match is None:
            continue
        instance, quoted_name, address = match.groups()
        try:
            name = json.loads(quoted_name)
            addr = ipaddress.IPv6Address(address.partition("%")[0])
        except ValueError:
            continue
        if not addr.is_link_local:
            continue
        found.append(
            {"instance": instance, "name": name, **by_addr.pop(addr, {"rssi": None})}
        )
    return found + list(by_addr.values())


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("status")
    visible = commands.add_parser("visible")
    visible.add_argument("state", choices=["on", "off"])
    commands.add_parser("peers")
    send = commands.add_parser("send")
    target = send.add_mutually_exclusive_group(required=True)
    target.add_argument("--to")
    target.add_argument("--mac")
    send.add_argument("files", nargs="+")
    args = parser.parse_args()

    if args.command == "status":
        print(json.dumps(status()))
    elif args.command == "visible":
        if args.state == "on" and radio_property("State", "unavailable") != "up":
            parser.exit(1, "Owly radio is not up\n")
        return unit("start" if args.state == "on" else "stop")
    elif args.command == "peers":
        try:
            result = subprocess.run(
                [OWLY, "browse", "--seconds", "6"],
                capture_output=True,
                text=True,
                errors="replace",
                timeout=15,
            )
            lines = result.stdout.splitlines()
        except subprocess.TimeoutExpired:
            lines = []
        print(json.dumps(devices(lines, radio_property("Peers", []))))
    else:
        if args.mac and not MAC.fullmatch(args.mac):
            parser.error("invalid device MAC")
        if not all(Path(name).is_absolute() for name in args.files):
            parser.error("expected local absolute file paths")
        receiver = f"--mac={args.mac}" if args.mac else f"--to={args.to}"
        os.execv(OWLY, [OWLY, "send", receiver, "--", *args.files])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
