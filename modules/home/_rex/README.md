# Rex

## Configuration

`den.aspects.rex` is explicitly included by Elphael, Dectus, Erdtree,
Farum Azula, Malenia, Melina, Rennala, Scarab, Siofra, Volcano Manor, and
Torrent. It is not a global `den.default`.

Shared service and CLI wiring lives in [`../rex.nix`](../rex.nix). Native Mac
preferences and theme activation live in [`../rex-darwin.nix`](../rex-darwin.nix),
which contributes to the same aspect with a Darwin platform guard—not to the
torrent host aspect. The optional Linux GUI has its own
[`rex-linux` aspect](../rex-linux.nix).

Linux hosts install the Rex CLI and use **SSH-only remote access**. No Rex
login server, shared server, TCP listener, Tailscale Serve mapping, embedded
Tailscale node, or Rex firewall opening is configured. SSH starts or reuses
`joe`'s personal server on its local Unix socket. Home Manager enables the
personal `rex.service` user unit on Linux, wanted by `default.target`. It is
not a system-wide login or shared server.

Dotfiles derive the Rex host list from the flake's configurations: Linux
machines with the personal Rex server enabled, plus Mac machines using the
native Rex app. Every machine gets the same list, including its own hostname
when it qualifies. Entries use `ssh://<host>` even for self, so they still
point to the right machine when another client follows that Rex home. Rex uses
the system SSH client, so existing SSH aliases, users, ports, keys, and agents
apply. There is no Rex Tailscale sign-in or tag-based Rex principal.

```fish
rex -S elphael ls --json
# Or connect without using the host list:
rex -S ssh://elphael ls --json
```

For other clients, add `ssh://<host>` as the remote host address. Both the client
and remote Rex binary must support SSH endpoints. The pinned package includes
SSH support; Torrent's native app must also be recent enough. The old HTTP and
HTTPS Rex endpoints are no longer used.

The former `restart-rex-server` alias is removed: there is no system login
server to restart. **A switch that updates the managed Linux user service
restarts it, ending its terminal sessions.** The unit explicitly uses
`X-SwitchMethod=restart` so switches pick up server updates. Save work and
arrange another SSH connection before switching; lingering does not protect
sessions from a service restart.

Torrent keeps its native **Rex.app**, including its bundled server and CLI.
The aspect exposes that CLI on PATH without installing another Mac server.

Home Manager writes `~/.config/rex/dotfiles.lua`. Activation merges a marked
loader into the beginning of writable `init.lua`, preserving all other Lua.
Local settings run afterward and can override managed bindings. The candidate
is checked with the installed Rex CLI before replacement; changed local files
get a timestamp-independent unique backup alongside them. Activation reloads
an already-running local server but never starts one just to reload config.

Rex lists declared hosts alphabetically by label, regardless of Lua declaration
order. Declared entries show their source in Settings; they are not manually
editable. A generated entry says the server is configured, not that it is
installed or reachable right now. iOS devices are clients only. The Windows
server has separate installation instructions; this aspect does not manage it.

## Login without a desktop session

The Rex aspect sets `users.users.joe.linger = true` on every included Linux host,
including Elphael. Lingering keeps the user manager and `/run/user/<uid>` alive
after the final SSH or desktop logout, preserving the personal Rex socket and
running sessions. User services can run while logged out and use resources;
this does not grant remote access or open ports.

The user service maintains the personal server independently of graphical
login. SSH can also start a missing personal server on demand. Rex must be
on the noninteractive SSH PATH; the aspect installs it in the system profile
as well as the Home Manager profile. `REX_AUTOSTART=0` disables the CLI's
on-demand startup, not the managed systemd user service. Do not run
`rex server install` for these Home Manager units. On an unmanaged Linux
machine it can set up a personal server, including over SSH when installation
is intended. Starting with `preview.23`, new Linux terminals also read
`/etc/environment`; changes to it don't update already-running terminals.

```fish
loginctl show-user joe -p Linger
ssh elphael 'command -v rex'
rex -S ssh://elphael ls --json
```

When switching from the old configuration, NixOS removes the managed login
server and its Rex-specific firewall opening. Existing personal/account servers
are not deliberately stopped. Check `tailscale serve status` for any older
manually configured Rex mappings (such as 7297 or 8443), and remove only confirmed
obsolete Rex mappings, not unrelated services.

## Package installation

The Rex package channel is public and requires no auth token or netrc, including
for first-time bootstrap and CI. The `rex` flake input follows tagged previews
at `https://pkgs.superlogical.com/rex/nix/preview.tar.gz`; `flake.lock` pins the
resolved immutable preview. `nix flake update rex rex-rune` refreshes the server
and the independently pinned Linux client.

For a standalone installation outside this configuration:

```fish
nix profile add https://pkgs.superlogical.com/rex/nix/preview.tar.gz
```

The Rex aspect does not decrypt package credentials or override Nix's netrc.
Existing cache authentication is independent; Erdtree's Garnix build sandbox
continues to use the cache netrc.

## Ghostty parity

The shared Lua fragment matches the explicitly configured Ghostty shortcuts:

| Key | Rex behavior |
| --- | --- |
| Ctrl+Shift+T | New tab |
| Ctrl+Shift+W | Close pane |
| Ctrl+Shift+N | New client window |
| Ctrl+Enter | Left at Rex's default (passed to terminal applications) |
| Shift+Enter | Send ESC followed by CR, matching Ghostty |

On Torrent, Nix also sets TX02 Nerd Font Mono at 13 points, disables copy on
select, keeps Fish as the startup shell, and enables the theme palette. Native
macOS menu equivalents keep Cmd+C/V for Copy/Paste, replacing the old
Ctrl+Shift+C/V overrides without changing other custom menu equivalents.
App restart may be needed for native defaults.

The managed Gruvbox Dark Hard theme is copied from Ghostty's shipped theme.
Activation imports and selects it through Rex's supported client actions.
Open Rex and enable **Settings → Rex Server → Remote Control** before switching.
With no running app, import is deferred until the next switch. A rejected import
fails visibly and is not recorded as complete. Unchanged themes are not imported
again, but each switch reselects the configured theme. Other imported themes are
left alone.

The documented Rex Lua API does not expose Ghostty's exact 95% opacity, 4-pixel
padding, 1-GB scrollback limit, font-feature list, or cursor/mouse options. Those
are not represented by invented settings.

### Linux GUI

Elphael additionally includes `den.aspects.rex-linux`. It installs the
`rex-rune` client from its independently pinned flake and a **Rex Rune**
desktop entry (`dev.shuv.rex-rune`) that selects the shared Ghostty font.
Update the Nix input rather than using an in-app installer. Rune's workspace
state under `~/.config/rex-rune` is client-owned and not replaced on switch.
The client adds no separate server service; server lifetime still belongs to
the shared Rex aspect. Other Linux hosts receive the CLI/server configuration,
not this GUI aspect. Torrent keeps its native Mac app.

## Verify after switching

On a Linux host:

```fish
loginctl show-user joe -p Linger
systemctl --user status rex.service
# Neither old system unit should be active (a nonzero exit is expected):
systemctl is-active rex-login-server rex-tailscale-serve
rex config check
rex hosts --json
```

From Torrent, use the SSH address directly:

```fish
rex -S ssh://elphael ls --json
```

Configuration tests are available as `checks.<system>.rex-config` for upstream
supported systems. They cover Lua merging, backup/idempotence, validation
failure preservation, theme import retries, and the real CLI's Lua validation.
`checks.x86_64-linux.rex-services` (also on aarch64-linux) evaluates the service
wiring with and without Tailscale: generated SSH entries for enabled servers,
lingering, system CLI availability, the personal Linux user service and its
restart policy, no system-wide shared/login service or Rex firewall opening,
and the native Mac server remaining unmanaged by systemd. `checks.<linux-system>.rex-linux`
contains the GUI aspect's package and desktop-entry assertions. A check being
defined is not evidence that it currently passes.

## Agent integration

The agent-skills Rex skill reads the current CLI's official guide rather than
vendoring a version-specific command manual. The shared startup hook appends
Rex's official context only inside a Rex terminal. Pi's `pi-custom` extension
adds the same context with a bounded local subprocess, no server autostart, and
no effect outside Rex. It does not rename sessions or imply permission to open
panes. Starting with `preview.23`, new terminals set `REX_BLOCK` but no longer
set `REX_SESSION`. Current Rex accepts `-s "$REX_BLOCK"` to address the containing
session; use `rex whoami --json` when you need its actual session ID. Older
terminals can still have both variables. Do not run `rex skill setup` over
Nix-managed agent configuration.

The optional read-only community MCP is at
<https://www.superlogical.com/rex/community-mcp>. It requires Discord OAuth and
Rex Beta Discord membership even though package downloads are public. It is not
automatically installed or authenticated by this aspect.
