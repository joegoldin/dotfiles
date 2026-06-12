# dotfiles

Nix configuration for all of my machines — NixOS workstations and servers,
a MacBook (nix-darwin), and a Steam Deck — with home-manager everywhere,
organized around the [dendritic pattern](https://github.com/mightyiam/dendritic)
with [den](https://github.com/denful/den) as the engine and
[drowse](https://github.com/figsoda/drowse) for dynamic derivations.

| Output | Machine | Role |
| --- | --- | --- |
| `joe-desktop` | desktop tower (AMD GPU, Plasma) | daily driver |
| `office-pc` (+ `office-pc-installer` ISO) | compute box (ROCm + vllm) | ML/training |
| `Joes-MacBook-Pro` | MacBook (aarch64-darwin) | laptop |
| `joe-steamdeck` | Steam Deck (Jovian) | gaming |
| `cloud-proxy` | VPS | caddy reverse proxy + fail2ban |
| `oracle-cloud-bastion` (hostName `bastion`) | Oracle Cloud | pelican game servers, tailnet entry |
| `racknerd-cloud-agent` | VPS | attic binary cache server |

Day-to-day: `just build` / `just switch` (see the Justfile), or `nh os
switch` directly. Secrets (agenix), agent-skills, and assets are personal
repos fetched as flake inputs over ssh — no submodules; a plain clone is
all you need.

## The big picture

This repo used to be **host-first**: a 940-line `flake.nix` called
`nixosSystem` once per machine, each call wiring up home-manager, agenix,
overlays and a `specialArgs` grab-bag, importing a `hosts/<name>/` tree
that imported shared files from `hosts/common/`. To answer "what does the
fish setup look like?" you read five files across three directories; to
add a feature to two hosts you edited both host trees.

Now it is **feature-first**. A feature lives in exactly one file as an
*aspect* — a bundle that can carry NixOS config, darwin config, and
home-manager config together. Machines are one-line *entities* that select
aspects. Nothing imports anything by hand at the top level: the directory
tree itself is the wiring.

```
flake.nix ──▶ flake-parts.mkFlake (import-tree ./modules)
                     │
                     ▼  every non-underscore .nix file under modules/
                     │  is loaded as a flake-parts module, automatically
                     ▼
              den (one flake-parts module among them)
                     │  reads den.hosts.* entities + den.aspects.* registry
                     ▼
              nixosConfigurations.* / darwinConfigurations.*
```

Three projects make this work, each doing one job:

| Project | Job |
| --- | --- |
| **flake-parts** | The module system applied to the flake itself. Outputs (`packages`, `overlays`, `nixosConfigurations`, …) become *options* that many small modules can contribute to, instead of one giant attrset in `flake.nix`. |
| **import-tree** | `inputs.import-tree ./modules` returns every `.nix` file under `modules/` as an import list. This is what makes "drop a file in, it's live" work. Paths containing `/_` are skipped — that's the escape hatch for files that *aren't* flake-parts modules. |
| **den** | An aspect engine on top. It defines the `den.hosts` / `den.aspects` options, resolves which aspects apply to which entity, and instantiates `nixosSystem`/`darwinSystem` for you. |

The name *dendritic* refers to the underlying pattern: **every file is a
module of one top-level configuration**, and lower-level configs (NixOS,
home-manager) are values *inside* it rather than separate evaluations
wired by hand.

## What evaluating a host actually does

When you run `nh os switch` or `just build` (which evaluate
`.#nixosConfigurations.joe-desktop`):

1. Nix calls `flake.nix`'s one-line `outputs`. flake-parts evaluates the
   ~90 files import-tree found under `modules/` as one module system.
2. One of those files (`modules/flake/den.nix`) imports `den.flakeModule`,
   which declares the `den.*` options. All the other files' `den.aspects.*`
   and `den.hosts.*` definitions merge into them.
3. den sees the entity `den.hosts.x86_64-linux.joe-desktop.users.joe`.
   It resolves the host's aspect (`den.aspects.joe-desktop` — name-matched),
   walks its `includes` graph, pulls in the schema-level batteries, and
   sorts every class block it finds into buckets: `nixos` blocks become
   modules of the NixOS eval, `homeManager` blocks become modules of
   joe's home-manager eval, `os` blocks go to both nixos and darwin.
4. den calls `nixosSystem { modules = [ ...all of that... ]; }` and
   assigns the result to `flake.nixosConfigurations.joe-desktop`.

So there is still a perfectly normal NixOS evaluation at the bottom —
den just *assembles* its module list from the aspect graph instead of you
writing it out.

## den's vocabulary, as used here

**Entity** — a thing that exists: a host or a user. Declared once:

```nix
den.hosts.x86_64-linux.joe-desktop.users.joe = { };
```

That single line gives you a flake output, a hostname (via battery), a
user account with a home-manager environment, and a pointer at the
host's aspect. Entities carry options (`hostName`, `instantiate`, …):
the bastion keeps its old output name but a different machine name with
`hostName = "bastion"`; the mac overrides `instantiate =
inputs.nix-darwin.lib.darwinSystem` because den's default looks for an
input literally named `darwin`.

**Aspect** — what something *does*. An attrset whose keys are mostly
*class blocks* plus some structural fields:

```nix
den.aspects.fish.homeManager = { pkgs, lib, config, ... }: { ... };
#          ────  ───────────
#          name  class block (a normal home-manager module)
```

Class blocks are ordinary modules of that class — everything you already
know about NixOS/home-manager modules applies inside them. The classes
used in this repo: `nixos`, `darwin`, `homeManager`, and `os` (a den
battery forwards `os` into both nixos and darwin — see
`modules/nix/settings.nix` and `modules/services/attic.nix`).

**includes** — aspects composing aspects. This is the only "imports"
you write anymore:

```nix
den.aspects.joe-desktop = {
  includes = [
    den.aspects.nix-settings
    den.aspects.attic
    den.aspects.home-baseline
    den.aspects.plasma
    den.aspects.zen
    ...
  ];
  nixos = { ... };
};
```

A host's `includes` list *is* its feature menu. Adding/removing a
capability is one line. (`den` arrives as a module argument in any
flake-parts file — `{ den, ... }:` — giving you `den.aspects.*` and
`den.batteries.*` to reference.)

**provides** — directed composition. Where `includes` says "I am also
X", `provides` says "I give X *to my counterpart entities*":

- `modules/users/joe.nix` uses `provides.to-hosts.nixos` and
  `provides.to-hosts.darwin` to push the OS account (`users.users.joe`)
  onto whatever host the user lands on — the user defines their own
  account once, for both platforms.

**Batteries** — aspects den ships. Three are wired for every host via
`den.schema.host.includes` in `modules/flake/den.nix`:

- `den.batteries.hostname` — `networking.hostName` from the entity's
  `hostName`. No host sets its hostname by hand anymore.
- `den.batteries.host-aspects` — **the key one**: it projects the
  `homeManager` blocks found in a *host's* aspect tree onto that host's
  *users*. This is the mechanism behind "the host includes
  `den.aspects.zen`, therefore joe's home on that host has zen". Without
  it, host-included hm blocks would go nowhere.
- `den.aspects.hm-settings` (ours, not a battery) — the home-manager
  plumbing every host repeated before: `useGlobalPkgs`,
  `useUserPackages`, the timestamped `backupCommand`.

**Schema and defaults** — `den.schema.user.classes = [ "homeManager" ]`
makes every user entity a home-manager user; `den.default.<class>` merges
config into every entity of a class (we use it for `stateVersion`
defaults, which hosts may override — cloud-proxy `mkForce`s 25.11).

## The repo's patterns, file by file

### 1. One file = one feature

`modules/home/zed.nix`, `modules/system/gaming.nix`,
`modules/ai/claude.nix` — each declares exactly one aspect. The file's
*location* is taste; the aspect *name* is identity. Browsing `modules/`
is browsing the feature list.

### 2. Aspect merging by name (hosts as directories of concerns)

The same aspect can be defined in many files; den merges them. Host
directories exploit this — `modules/hosts/joe-desktop/` contains
`default.nix` (entity + includes + secrets), `system.nix` (boot, base
services), `machine.nix` (hardware tuning), `home.nix` (host-specific
home config), `wallpaper.nix`, `nut.nix`, `vban-send.nix`, … — and every
one of them assigns into `den.aspects.joe-desktop.*`. One aspect, a
directory of single-purpose files, no aggregator imports anywhere.

Corollary to remember: **dropping a non-underscore file into
`modules/hosts/joe-desktop/` activates it.** There is no "imported but
commented out" — that's what underscores are for (see
`_hyprwhspr.nix`, kept disabled by its name).

### 3. Features carry their own plumbing

The old flake wired `plasma-manager` into `sharedModules`,
`nix-attic-infra`'s hm module into another host's `sharedModules`,
`audiomemo`'s module into an aggregator… Now every aspect imports the
upstream module *it* needs inside its own class block:

- `modules/home/plasma.nix` imports `plasma-manager.homeModules.plasma-manager`
- `modules/services/attic.nix` imports the attic-client hm module
- `modules/ai/claude.nix` imports the agent-skills modules

A host that includes the aspect gets the machinery with it. (Invariant:
each upstream hm module is imported by exactly **one** aspect — two
aspects importing the same anonymous module attrset would collide.)

### 4. The cross-class aspect (the den payoff)

`modules/services/attic.nix` is the showcase: the `os` block adds the
binary cache as a substituter on NixOS *and* darwin; the `homeManager`
block configures the `attic` CLI client. One file answers "how does this
machine relate to the cache". `modules/nix/settings.nix` is the same
shape for nix daemon settings (an `os` core + a `nixos`-only tail for
channels/nh).

### 5. Bundles are aspects too

`modules/home/baseline.nix` is nothing but an `includes` list (+ the xdg
dotconfig copy): the "full home environment" bundle that workstations,
the mac, and the bastion include — while the lean servers and the deck
pick features individually. Note what it *doesn't* contain:
git/fish/gh/gpg/starship ride on the **joe user aspect** and reach every
host automatically, because they're properties of *the user*, not of any
host. That user/host split is deliberate: ask "is this mine everywhere,
or this machine's?" and the aspect goes in `users/joe.nix`'s includes or
the host's.

### 6. Closures instead of specialArgs

The old tree passed `username`, `keys`, `dotfiles-secrets`,
`commonOverlays`… through `specialArgs` into every module. Now a feature
file *is* a flake-parts module, so it receives `inputs` (and `config`,
the flake-level config) as ordinary arguments, and binds what it needs
lexically:

```nix
{ inputs, ... }:
let
  meta = import ../_lib/meta.nix;                       # username/email
  domains = import "${inputs.dotfiles-secrets}/domains.nix";
in
{
  den.aspects.attic.homeManager = { ... uses domains ... };
}
```

The inner class block closes over those `let` bindings. No magic
arguments, no eval-order traps, and grep can always tell you where a
value comes from. Rule: **never add module arguments for repo-level
data** — close over `inputs`, import `_lib/meta.nix`.

### 7. Underscore = "not a flake-parts module"

import-tree skips any path containing `/_`. The permanent underscore set:

- `modules/hosts/*/_hardware-configuration.nix`, `_disk-config.nix` —
  tool-generated NixOS modules, imported explicitly by the host aspect
- `modules/flake/_pkgs/` — callPackage-style package sources
- `modules/flake/_overlays/` — overlay definitions
- `modules/_data/` — dotconfig tree, fonts, the microvm generator
- `modules/_lib/meta.nix` — a plain attrset
- payload files next to their aspect: `modules/home/fish/_aliases.nix`
  (functions the fish module calls), `modules/home/zen/_addons.nix`,
  `modules/hosts/*/_plasma-panels.nix` (large generated config),
  `modules/home/bin/_scripts/` (the script library)

One special case: `modules/home/bin/_module.nix` is a *complete* hm
module kept standalone because microVM guests import it by path at
runtime (`modules/_data/microvm/fish-guest.nix` → `common-guest.nix`),
entirely outside den. Don't inline it into the aspect.

### 8. drowse (dynamic derivations) instead of IFD

[drowse](https://github.com/figsoda/drowse) evaluates Nix *at build
time* (recursive-nix) instead of eval time:
`inputs.drowse.lib.${system}.callPackage ./file.nix { }` produces a
dynamic derivation — fine-grained caching with no import-from-derivation
and no committed codegen (`drowse.crate2nix` does this per-crate for
Rust). It needs three experimental features (`ca-derivations`,
`dynamic-derivations`, `recursive-nix`) on the **building** machine, so
enablement is the opt-in aspect `den.aspects.dynamic-derivations` —
currently included only by joe-desktop. The repo's one real IFD
(mkwindowsapp splicing a built script's text at eval time) was fixed to
a runtime `source` instead; drowse is there for when you genuinely need
eval-at-build (lockfile-driven package trees, Rust side projects).

## Cookbook

**Add a feature** — create `modules/home/foo.nix`:

```nix
{ ... }:
{
  den.aspects.foo.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.foo ];
  };
}
```

…and add `den.aspects.foo` to a host's `includes` (or
`home-baseline.nix` for everywhere-with-a-full-home, or
`users/joe.nix` for literally-everywhere).

**Give a feature a darwin half** — add a `darwin` (or `os`) block to the
same file. That's the whole point: the mac side of a feature lives next
to its linux side.

**Host-specific tweak of a shared feature** — put it in the host's
`home.nix` (or a new sibling file): host aspect hm blocks merge with
feature aspect hm blocks in the user's home eval, ordinary module-system
rules (`mkDefault`/`mkForce`) arbitrate.

**New host** — `modules/hosts/<name>/default.nix` with the entity line,
an `includes` list, external module imports (disko/agenix/…), and age
secrets; siblings for system/home config; `_hardware-configuration.nix`
from `nixos-generate-config`. Output name = entity name.

**New secret** — `age.secrets.<name>` in the host's `default.nix`
(secrets are per-host trust decisions, so they stay with the host), file
from `${inputs.dotfiles-secrets}/...`.

**New flake input** — add to `flake.nix`, then reference it only inside
the one aspect that owns it.

## Invariants and gotchas

- **Names are stable**: entity names = flake output names = what
  Justfile/nh expect. `hostName` exists for when the machine name must
  differ (bastion).
- **Every non-underscore file under `modules/` is live.** New file =
  active module. Disable by underscore-renaming, not commenting the
  import (there are no imports to comment).
- **List merging**: joe's base `extraGroups = [ "wheel" "networkmanager" ]`
  is a *plain* definition so host additions concatenate. If you
  `mkDefault` a list, any plain definition *replaces* it instead of
  merging — that's why the account base is plain and scalars like
  `home.username` are `mkDefault`.
- **den is pinned** (`?rev=` in flake.nix) like every other input —
  it's a young framework; bump deliberately and verify with a closure
  diff (`nvd diff`) against the previous generation before switching.
- **darwin from linux** evaluates only until agent-skills needs an
  aarch64-darwin build (pre-existing IFD); full mac verification happens
  on the mac.
- The microvm generator (`modules/_data/microvm/module-gen.py`) writes
  *absolute repo paths* into generated VM flakes — if you move
  `fish-guest.nix`, `common-guest.nix`, or `bin/_module.nix`, update the
  generator + `test-data/*.expected` and run `module-gen-test.py`.
- `modules/_lib/meta.nix` is the single source for username/email.

## Mental model in one paragraph

Everything under `modules/` is one big module system; den gives it a
vocabulary of *features* (aspects) and *things* (entities). A feature is
one file that owns every side of itself — linux, mac, home, upstream
modules, secrets-derived config. A machine is a list of features plus
its quirks, each quirk a small file merging into the machine's aspect.
The user is also an aspect, carrying the account and universal tools to
every machine. To understand anything, find its file; to change where it
applies, edit an `includes` list; to add something new, add a file. The
tree is the wiring.

## Attribution

- **mkWindowsApp** (`modules/flake/_pkgs/mkwindowsapp/`) — a Nix function
  for installing Wine-compatible Windows applications, vendored from
  [emmanuelrosa/erosanix](https://github.com/emmanuelrosa/erosanix/tree/master/pkgs/mkwindowsapp)
  by Emmanuel Rosa (MIT), itself based on
  [lucasew/nixcfg's wrapWine.nix](https://github.com/lucasew/nixcfg/blob/fd523e15ccd7ec2fd86a3c9bc4611b78f4e51608/packages/wrapWine.nix).
- **mac-app-util** (`modules/flake/_pkgs/mac-app-util/`) — a Python port of
  [hraban/mac-app-util](https://github.com/hraban/mac-app-util)
  (© Hraban Luyat, **AGPL-3.0** — this component keeps its upstream license,
  unlike the rest of the repo). Ported because the Common Lisp original
  can't run on macOS 27.
- **watchyt** (`modules/home/bin/_scripts/watchyt.nix`) — customized port of
  [bradautomates/claude-video](https://github.com/bradautomates/claude-video)
  (MIT).
- **llm-cmd-comp fish binding** (`modules/home/fish/_init.nix`) — the
  `__llm_cmdcomp` function is from
  [CGamesPlay/llm-cmd-comp](https://github.com/CGamesPlay/llm-cmd-comp)
  (Apache-2.0).

## License

[MIT](./LICENSE.md)
