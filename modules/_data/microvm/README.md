# microVM subsystem

Declarative, disposable Linux microVMs on elphael, built on
[microvm.nix](https://github.com/microvm-nix/microvm.nix). This directory
holds the data and guest modules; the host service and CLI live elsewhere
in the module tree.

| Piece | Where | Job |
| --- | --- | --- |
| Host aspect | [`modules/system/microvm-host.nix`](../../system/microvm-host.nix), `den.aspects.microvm-host` | Bridge, NAT, dnsmasq for `.vm`, state directories, profiles, and the `vm-module-gen` wrapper |
| `vm` CLI | [`modules/home/bin/_scripts/vm/`](../../home/bin/_scripts/vm) | `vm new/start/ssh/pkg/profile/export/update/...` lifecycle commands |
| Generator | [`module-gen.py`](module-gen.py) | Renders a VM's metadata and profile into `module.nix` and `flake.nix` |
| Profiles | [`profiles/`](profiles) | `minimal` and `desktop` package/resource presets |
| Guest baseline | [`common-guest.nix`](common-guest.nix) | Users, SSH keys, networking, microVM storage/shares, and Home Manager wiring |
| Guest shell | [`fish-guest.nix`](fish-guest.nix) | Trimmed fish environment and the repo's script library |
| Golden tests | [`module-gen-test.py`](module-gen-test.py) and [`test-data/`](test-data) | Compare generated files with checked-in fixtures |

## How a VM comes to exist

1. `vm new <name>` writes `/var/lib/vm-specs/<name>/meta.json` with the
   selected profile, packages, and resources, then calls `vm-module-gen`.
2. The generator renders `module.nix` with the requested packages and GUI
   features. It also renders a standalone `flake.nix` and mirrors `meta.json`.
3. The flake references this checkout through an absolute `git+file://` URL.
   It follows dotfiles' nixpkgs, microvm-nix, and Home Manager inputs, imports
   `common-guest.nix`, and passes the metadata, SSH public keys, and
   `fish-guest.nix` through `specialArgs`. Its lock pins the checkout revision.
4. `vm start <name>` builds and runs the VM; dnsmasq makes it reachable as
   `<name>.vm`. Runtime disks and runner state live under
   `/var/lib/microvms/<name>/`, separate from the CLI's specs.

Generated guests evaluate outside den and import their own nixpkgs set with
dotfiles' exported overlays. They do not directly reuse the host's shared
`packageSets.stable` value. The guest shell supplies `customPackages = { }`
and `vmGuest = true` to the standalone script module: host-only scripts are
filtered out, and tools such as watchyt can use optional applications on PATH
rather than importing the host's application set.

## Trust boundary

These are convenience VMs, not a sandbox for hostile workloads. The host
trusts `vmbr0`, guests can reach host services, and the guest firewall defaults
to disabled. Guests have passwordless sudo and simple initial console
passwords; SSH password authentication is disabled. Shared directories expose
host files to the guest, writable unless marked read-only. Do not place
untrusted code or secrets in a VM on the assumption that the bridge, root
account, or shared mounts isolate it from the host.

## Editing and tests

Run the golden tests from the repository root with a Python environment that
has pytest:

```fish
pytest modules/_data/microvm/module-gen-test.py -v
```

Running `python3 module-gen-test.py` directly does not invoke pytest or run
the tests. The expected flake fixtures include `/home/joe/dotfiles` as the
checkout path; account for that when testing from another checkout location.
Review fixture differences before updating `.expected` files.

Moving `common-guest.nix`, `fish-guest.nix`, or
[`modules/home/bin/_module.nix`](../../home/bin/_module.nix) requires updating
the generator and any affected fixtures. Existing VMs retain their generated
files and lock; `vm update <name>` re-renders the files, refreshes the lock,
and rebuilds the runner. It does not restart an already-running VM unless
passed `--restart`.

Guest imports must remain ordinary NixOS/Home Manager modules, not den
aspects. Keep the standalone `bin/_module.nix` entry point when changing the
host's script wiring.
