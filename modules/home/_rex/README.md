# Rex

## Configuration

`den.aspects.rex` is explicitly included by Elphael, Dectus, Erdtree,
Farum Azula, Malenia, Melina, Rennala, Scarab, Siofra, Volcano Manor, and
Torrent. It is not a global `den.default`.

Linux hosts install the Rex CLI and use **SSH-only remote access**. No Rex
login server, shared server, TCP listener, Tailscale Serve mapping, embedded
Tailscale node, or Rex firewall opening is configured. SSH starts or reuses
`joe`'s personal server on its local Unix socket. Home Manager does not install
a separate personal systemd service.

Managed host entries use `ssh://<host>`. Rex uses the system SSH client, so
existing SSH aliases, users, ports, keys, and agents apply. There is no Rex
Tailscale sign-in or tag-based Rex principal. SSH itself may still travel over
Tailscale if that is how the existing SSH connection is configured; unrelated
Tailscale services and access policy are unchanged.

```fish
rex -S elphael ls --json
# Without the managed host list:
rex -S ssh://elphael ls --json
```

For other clients, add `ssh://<host>` as the remote host address. Both the client
and remote Rex binary must support SSH endpoints. The pinned package includes
SSH support; Torrent's native app must also be recent enough. The old HTTP and
HTTPS Rex endpoints are no longer used.

The former `restart-rex-server` alias is removed: there is no system login
server to restart. Do not stop a personal server to upgrade it while its
sessions are needed; stopping it ends those sessions.

Torrent keeps its native **Rex Beta.app**, including its bundled server and CLI.
The aspect exposes that CLI on PATH without installing another Mac server.

Home Manager writes `~/.config/rex/dotfiles.lua`. Activation merges a marked
loader into the beginning of writable `init.lua`, preserving all other Lua.
Local settings run afterward and can override managed bindings. The candidate
is checked with the installed Rex CLI before replacement; changed local files
get a timestamp-independent unique backup alongside them. Activation reloads
an already-running local server but never starts one just to reload config.

The host list includes the other Linux machines as future connection
targets. A menu entry is not evidence that a server has been deployed. Gitea,
Roundtable, and Travelboi24 have no host configuration in this repository and
need a separate installation once accessible. iOS devices and the Windows
machine are not supported by the current public server packages.

## Login without a desktop session

The Rex aspect sets `users.users.joe.linger = true` on every included Linux host,
including Elphael. Lingering keeps the user manager and `/run/user/<uid>` alive
after the final SSH or desktop logout, preserving the personal Rex socket and
running sessions. User services can run while logged out and use resources;
this does not grant remote access or open ports.

SSH starts a missing personal server on demand. No graphical login or system
login server is needed. Rex must be on the noninteractive SSH PATH; the aspect
installs it in the system profile as well as the Home Manager profile.
`REX_AUTOSTART=0` on the remote machine prevents automatic startup.

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
for first-time bootstrap and CI. The `rex` flake input uses
`https://pkgs.superlogical.com/rex/nix/snapshot.tar.gz`; `flake.lock` pins the
resolved immutable snapshot.

For a standalone installation outside this configuration:

```fish
nix profile add https://pkgs.superlogical.com/rex/nix/snapshot.tar.gz
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
are not represented by invented settings. Linux GUI appearance is pending an
upstream GUI/settings interface; the portable Lua bindings are ready for it.

## Verify after switching

On a Linux host:

```fish
loginctl show-user joe -p Linger
# Neither old system unit should be active:
systemctl is-active rex-login-server rex-tailscale-serve
rex config check
rex hosts --json
```

From Torrent, use the generated host labels:

```fish
rex -S elphael ls --json
```

Configuration tests are available as `checks.<system>.rex-config` for upstream
supported systems. They cover Lua merging, backup/idempotence, validation
failure preservation, theme import retries, and the real CLI's Lua validation.
`checks.x86_64-linux.rex-services` (also on aarch64-linux) evaluates the service
wiring with and without Tailscale: SSH host entries, lingering, system CLI
availability, no personal/shared/login service or Rex firewall opening, and
the native Mac server remaining unmanaged by systemd.

## Agent integration

The agent-skills Rex skill reads the current CLI's official guide rather than
vendoring a version-specific command manual. The shared startup hook appends
Rex's official context only inside a Rex terminal. Pi's `pi-custom` extension
adds the same context with a bounded local subprocess, no server autostart, and
no effect outside Rex. It does not rename sessions or imply permission to open
panes. Do not run `rex skill setup` over Nix-managed agent configuration.

The optional read-only community MCP is at
<https://www.superlogical.com/rex/community-mcp>. It requires Discord OAuth and
Rex Beta Discord membership even though package downloads are public. It is not
automatically installed or authenticated by this aspect.
