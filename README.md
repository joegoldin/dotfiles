# dotfiles

My NixOS, nix-darwin, and Home Manager configuration. Features are composed
with [den](https://github.com/denful/den), following the
[dendritic pattern](https://github.com/mightyiam/dendritic).

## Usage

- `just build` builds this machine's configuration without activating it.
- `just boot` activates it at the next boot (NixOS only).
- `just switch` activates it now.

These commands select the host automatically and use nh. Personal flake
inputs require SSH access.

Use `just flake-update` to update inputs, or `just update-all` to update
inputs and custom packages, then build without activating. Review the
closure diff with `nvd diff` before switching.

## Layout

- `modules/hosts/` defines machines and their selected features.
- `modules/users/` holds user accounts and tools shared across machines.
- `modules/home/`, `modules/system/`, `modules/services/`, and `modules/ai/`
  contain feature aspects.
- `modules/flake/` wires up den, packages, and overlays.

To add a feature, define a `den.aspects.<name>` with its NixOS, darwin, or
Home Manager config, then add it to the host or user's `includes` list.
A feature imports any upstream modules it needs.

Every non-underscore `.nix` file under `modules/` loads automatically.
Use underscore-prefixed paths for helper files and generated data that
should only be imported explicitly. New files must be tracked for flakes
to see them.

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
