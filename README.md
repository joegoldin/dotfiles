# dotfiles

My NixOS, nix-darwin, and Home Manager configuration. Features are composed
with [den](https://github.com/denful/den), following the
[dendritic pattern](https://github.com/mightyiam/dendritic).

## Usage

- `just build` builds a system configuration without activating it.
- `just boot` installs it as the next boot generation (NixOS only).
- `just switch` activates it now.

These commands use nh. On macOS they select `torrent`. On Linux, the
[Justfile](Justfile) recognizes selected hostnames, selects `farum-azula` on
all aarch64 machines, and otherwise falls back to `elphael`. Check the target
before using them on other hosts; for an explicit build-only target, use:

```fish
nix build --no-link .#nixosConfigurations.rennala.config.system.build.toplevel
```

**The `build-to-*` recipes switch remote systems.** Their `--local` argument
changes where the build runs, not whether activation happens. The `deploy-*`
recipes are first-install operations using nixos-anywhere and disko; inspect
the target disk configuration and verify backups before using them.

Private `github:` inputs require GitHub credentials with repository access.
The nh and input-update recipes use the authenticated `gh` CLI. Direct Nix
commands need equivalent Nix access-token configuration; SSH access alone does
not authenticate a `github:` fetch. Keep tokens out of source and logs.

## Checks and updates

For evaluation without builds or activation:

```fish
nix flake check --no-build --option allow-import-from-derivation false
nix eval --raw .#nixosConfigurations.elphael.config.system.build.toplevel.drvPath --option allow-import-from-derivation false
nix eval --raw .#darwinConfigurations.torrent.config.system.build.toplevel.drvPath --option allow-import-from-derivation false
```

Evaluation does not prove that packages build or services work. `just check`
formats the Nix tree, validates flake outputs, then **builds** the current
platform's checks with nix-fast-build. `just fast-build packages` builds
package outputs without activation. Neither is an evaluation-only command.

Use `just flake-update` to update all inputs, or `nix flake update <input>` for
a targeted update. `just update-all` also updates custom Nix and Python
packages, then builds without activating. Review the source and closure diff
with `nvd diff` before switching. The [Nix utility review](modules/nix/_tools-review.md)
describes the update and GC tools and their limits.

## Layout and composition

- `modules/hosts/` defines machines and their selected features.
- `modules/users/` holds user accounts and tools shared across machines.
- `modules/home/`, `modules/system/`, `modules/services/`, and `modules/ai/`
  contain feature aspects.
- `modules/flake/` wires up den, shared package sets, packages, and overlays.
- `modules/_data/` contains explicitly imported data and helper modules.

To add a feature, define a `den.aspects.<name>` with its NixOS, darwin, or
Home Manager config, then add it to the host or user's `includes` list.
A feature imports any upstream modules it needs.

Every `.nix` file under `modules/` whose path contains no underscore-prefixed
component loads automatically. Use underscore-prefixed paths for helpers and
generated data that should only be imported explicitly. New files must be
tracked for Git-backed flakes to see them; this checkout uses `jj`, which
tracks new non-ignored files automatically.

Shared stable, unstable, and plain package sets live in
[`package-sets.nix`](modules/flake/package-sets.nix). Local packages and
upstream artifacts are composed alongside nixpkgs as `customPackages`, not
added as aliases under `pkgs`. Dependency patches and host-specific policies
still use overlays. See the [package-set guide](modules/flake/_overlays/README.md)
and [local package guide](modules/flake/_pkgs/README.md) before adding a package.

## AI configuration

[`modules/ai/pi.nix`](modules/ai/pi.nix) imports the shared agent-skills Pi
profile and supplies host integration. Its default is `openai/gpt-6.2-sol`;
the curated model list also includes `openai/gpt-6.2-astra`. The shared profile
itself defaults to Astra. Luna and non-OpenAI choices remain separate.

The dependency chain is **pi-nix → agent-skills → dotfiles**. Publish a pi-nix
change, update and publish agent-skills' `pi-nix` input, then update this
repository's `agent-skills` input. `just update-pi` changes the sibling pi-nix
checkout's upstream runtime and regenerates model data; it does not publish
that chain or activate a system. Updating only this repository's lock file
cannot select a new upstream Pi runtime on its own.

Elphael and volcano-manor share the
[`vllm` aspect](modules/ai/vllm.nix) and its isolated ROCm package scope.
**vLLM is disabled on both hosts** by the default
`programs.vllm-rocm.enable = false`. Enabling it adds the application and
its installed-package checks; the common Python environment keeps its
existing CPU-only Torch policy.

## Subsystem guides

- [Rex: SSH access, server lifetime, and GUI configuration](modules/home/_rex/README.md)
- [Script builder and `bins`](modules/home/bin/README.md)
- [Disposable microVMs](modules/_data/microvm/README.md)
- [Elphael pre-boot unlock](modules/hosts/elphael/README.md)
- [Rennala deployment](modules/hosts/rennala/DEPLOYMENT.md)
- [Pi Manager acceptance boundaries](modules/hosts/rennala/PI_MANAGER.md)

## Attribution

- mkWindowsApp (`modules/flake/_pkgs/mkwindowsapp/`): a Nix function
  for installing Wine-compatible Windows applications, vendored from
  [emmanuelrosa/erosanix](https://github.com/emmanuelrosa/erosanix/tree/master/pkgs/mkwindowsapp)
  by Emmanuel Rosa (MIT), itself based on
  [lucasew/nixcfg's wrapWine.nix](https://github.com/lucasew/nixcfg/blob/fd523e15ccd7ec2fd86a3c9bc4611b78f4e51608/packages/wrapWine.nix).
- mac-app-util (`modules/flake/_pkgs/mac-app-util/`): a Python port of
  [hraban/mac-app-util](https://github.com/hraban/mac-app-util)
  (© Hraban Luyat, AGPL-3.0; this component keeps its upstream license
  while the rest of the repo is MIT). Ported because the Common Lisp
  original can't run on macOS 27.
- watchyt (`modules/home/bin/_scripts/watchyt.nix`): customized port of
  [bradautomates/claude-video](https://github.com/bradautomates/claude-video)
  (MIT).
- llm-cmd-comp fish binding (`modules/home/fish/_init.nix`): the
  `__llm_cmdcomp` function is from
  [CGamesPlay/llm-cmd-comp](https://github.com/CGamesPlay/llm-cmd-comp)
  (Apache-2.0).

## License

[MIT](./LICENSE.md)
