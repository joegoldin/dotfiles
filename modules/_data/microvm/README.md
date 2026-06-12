# microVM subsystem

Declarative, disposable Linux microVMs on joe-desktop, built on
[microvm.nix](https://github.com/microvm-nix/microvm.nix). This directory
holds the *data half* of the subsystem; the host service and CLI live in
the module tree:

| Piece | Where | Job |
| --- | --- | --- |
| host aspect | `modules/system/microvm-host.nix` (`den.aspects.microvm-host`) | tap networking + NAT, dnsmasq serving the `.vm` domain, `/var/lib/vm-specs` state dir, installs the profiles below, wraps `module-gen.py` as `vm-module-gen` |
| `vm` CLI | `modules/home/bin/_scripts/vm/*.nix` (subcommands of the `bin` script builder) | `vm new/start/ssh/pkg/profile/export/...`, the user-facing lifecycle |
| generator | `./module-gen.py` | turns a VM's `meta.json` + a profile into `module.nix` + `flake.nix` |
| profiles | `./profiles/{minimal,desktop}.json` | base package/resource presets a VM starts from |
| guest baseline | `./common-guest.nix` | the NixOS module every guest imports: user, ssh keys, networking, home-manager wiring |
| guest shell | `./fish-guest.nix` | trimmed fish/home environment for guests; imports the repo's bin script library with `vmGuest = true` (strips `hostOnly` scripts) |
| golden tests | `./test-data/` + `./module-gen-test.py` | generator output fixtures; run `python3 module-gen-test.py` |

## How a VM comes to exist

1. `vm new <name>` writes `/var/lib/vm-specs/<name>/meta.json` (profile,
   packages, resources) and calls `vm-module-gen`.
2. `module-gen.py` deterministically renders `module.nix` (imports
   `common-guest.nix`, passes `meta` as a module arg) and a standalone
   `flake.nix` for the VM.
3. The generated flake references **this repo by absolute path** for its
   `microvm.nix` input, `common-guest.nix`, `fish-guest.nix`, and the bin
   script module; the dotfiles checkout is part of the guest's closure.
4. `vm start` builds/runs it; dnsmasq makes it reachable as `<name>.vm`.

## Editing rules

- `module-gen.py` is covered by golden files: after any change, run
  `python3 module-gen-test.py` and regenerate `test-data/*.expected` if
  the change is intentional.
- Because generated flakes embed repo paths, **moving or renaming**
  `common-guest.nix`, `fish-guest.nix`, or `modules/home/bin/_module.nix`
  requires updating `module-gen.py` + the `.expected` fixtures, and
  running `vm update` on existing VMs so their generated files are
  re-rendered.
- Guests evaluate outside den: anything they import must stay a plain
  NixOS/home-manager module file (that's why `fish-guest.nix` lives here
  and why `bin/_module.nix` exists).
