# Rex

## Configuration

`den.aspects.rex` is explicitly included by the managed Tailscale hosts:
Elphael, Dectus, Erdtree, Farum Azula, Malenia, Melina, Rennala, Scarab,
Siofra, Volcano Manor, and Torrent. It is not a global `den.default`.

On Linux it imports the upstream NixOS module and enables
`services.rex.loginServer.tailscaleServe.enable`. The login server allows only
the Tailscale identity in `dotfiles-secrets/domains.nix` to use `joe`; it grants
neither root nor anonymous access. Tailscale Serve forwards HTTPS **8443** to
`/run/rex/serve.sock`. Port 443 is left alone (Elphael uses it for Collie).
Tailscale must already be enrolled with HTTPS enabled.

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
