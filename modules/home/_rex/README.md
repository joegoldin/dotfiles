# Rex

## Configuration

`den.aspects.rex` is explicitly included by the managed Tailscale hosts:
Elphael, Dectus, Erdtree, Farum Azula, Malenia, Melina, Rennala, Scarab,
Siofra, Volcano Manor, and Torrent. It is not a global `den.default`.

On Linux it imports the upstream NixOS module and runs one direct **TCP 7297**
login-server listener, bound only to the host's Tailscale addresses. The firewall
opens 7297 only on `tailscale0`. Tailscale Serve is disabled: the direct listener
uses tailscaled WhoIs to verify the caller's device identity rather than Serve's
forwarded user headers. HTTP transport is encrypted by Tailscale/WireGuard;
Tailscale HTTPS certificates and a second embedded Tailscale node are not needed.

Only clients tagged **`tag:full-access`** may authenticate as `joe`, through the
explicit `tailscale:tag:full-access` principal. Untagged user identities and
other role tags alone do not authorize Rex login. No anonymous or root Rex access
is granted. A permitted Rex login can run commands as `joe`, so treat assignment
of `full-access` as granting shell access, not just permission to view terminals.

Rex servers need no dedicated role. Untagged devices and existing
`tag:ssh-in-only` servers are **inbound-only by default**: they cannot initiate
new tailnet SSH, Rex, ping, subnet, or exit-node connections. Replies to
incoming sessions are allowed. Full-access clients can reach all their services,
including Rex. Ordinary SSH still needs an authorized key; full-access clients
may use Tailscale SSH to tagged devices when enabled on the destination.
This policy does not restrict direct LAN/internet traffic outside Tailscale.
Do not give an isolated server `full-access`: permissions are additive.

Keep the initiating Mac tagged `full-access`. Existing `ssh-in-only` servers
can keep that identity without reauthentication; new general servers need no
extra tag just for isolation. Rex can use the
Mac's existing system Tailscale connection without a separate Rex Tailscale
sign-in. The tag must belong to the actual originating Tailscale node if an
embedded client is used instead.

Existing managed host aliases use direct endpoints; no additional aliases are
created. After the policy and server configuration are deployed:

```fish
rex -S elphael ls --json
# Without the managed host list:
rex -S http://joe@elphael:7297 ls --json
```

For other clients configure `http://joe@<full-MagicDNS-hostname>:7297`.
Old HTTPS endpoints are not interchangeable with the direct HTTP endpoint.
During activation the old managed Serve unit removes its 7297 HTTPS mapping.
Inspect `tailscale serve status` for older manually configured Rex mappings
(such as 8443); remove only obsolete Rex mappings, not unrelated services.

Home Manager installs the CLI and configuration, not a separate personal
systemd service. The system login server owns account-server startup. On logind
hosts, an account server is also the personal server local commands use, so
local and remote clients share sessions. No shared `rex.service`, embedded
Tailscale server node or anonymous TCP listener is needed. The direct listener
is permitted only on the Tailscale interface. Account servers survive
login-server restarts and upgrades.

On Linux, `restart-rex-server` runs
`sudo systemctl restart rex-login-server.service`, using the service definition
installed by `just switch`. This restarts only the system login server; existing
account servers and their programs keep running on their current Rex version.
Remote connections through the login server may briefly disconnect. Inspect
`journalctl -u rex-login-server` for restart failures.

Torrent keeps its native **Rex Beta.app**, including its bundled server and CLI.
The aspect exposes that CLI on PATH without installing another Mac server.

Home Manager writes `~/.config/rex/dotfiles.lua`. Activation merges a marked
loader into the beginning of writable `init.lua`, preserving all other Lua.
Local settings run afterward and can override managed bindings. The candidate
is checked with the installed Rex CLI before replacement; changed local files
get a timestamp-independent unique backup alongside them. Activation reloads
an already-running local server but never starts one just to reload config.

The host list includes the other Linux tailnet machines as future connection
targets. A menu entry is not evidence that a server has been deployed. Gitea,
Roundtable, and Travelboi24 have no host configuration in this repository and
need a separate installation once accessible. iOS devices and the Windows
machine are not supported by the current public server packages.

## Login without a desktop session

The system `rex-login-server.service` starts at boot under `multi-user.target`,
independently of the desktop. A permitted
Tailscale connection selects `joe`; PAM opens an account session and the login
server starts the account's Rex server if none is running, or reuses it otherwise.
The account server is started on demand; a persistent personal service is not
required. Other aspects may enable user lingering independently.

`rex server status` with no server argument checks the personal Unix socket,
not the system login server. A missing personal socket does not establish that
remote login is broken. To test the system login path, connect from another
tailnet device using `rex -S elphael ls --json` (with the managed host list), or
`rex -S http://joe@<hostname>.<tailnet>.ts.net:7297 ls --json`.
No graphical login is required. If this fails, inspect
`journalctl -u rex-login-server`;
account expiration/lock, PAM rejection, and Tailscale identity or ACL failures
are distinct from a missing local socket.

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
systemctl status rex-login-server rex-tailscale-serve
sudo tailscale serve status
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
wiring: no separate personal/shared service, restricted Serve on the default
7297, boot-time login-server activation, and the native Mac server remaining
unmanaged by systemd.

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
