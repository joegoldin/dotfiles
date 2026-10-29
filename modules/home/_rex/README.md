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

## Package authentication

The `rex` flake is pinned to an immutable snapshot URL. Its credential lives in
`dotfiles-secrets/rex-netrc.age`, encrypted for `all_keys` (including Torrent).
It never appears in the Nix store as plaintext.

On hosts with a key in `keys.nix`, agenix decrypts it and the aspect atomically
combines it with any existing `attic-netrc` into `/etc/nix/rex-netrc`. Existing
cache credentials and their read-group/mode are preserved. Erdtree's Garnix
build sandbox uses this combined file too, so evaluating the private Rex input
works in CI after Erdtree is switched. The cache proxy still uses only its
original cache netrc.

On Darwin, merging runs only after the agenix launchd job exits successfully;
a post-activation merge would race asynchronous decryption. On NixOS it depends
on the completed agenix activation step.

Dectus has no host key in `dotfiles-secrets/keys.nix`, so it does not get automatic
package-credential decryption. Build its closure on an authenticated host and
copy it over, or enroll its verified host key before building locally.

For first-time bootstrap, Nix needs access to the private flake *before* it can
build the generation that installs the secret. Use a protected temporary netrc
with `nix --option netrc-file /absolute/path/to/netrc …`, or copy a closure built
on an already-authenticated machine. Do not put the token into a flake URL.

## Ghostty parity

The shared Lua fragment matches the explicitly configured Ghostty shortcuts:

| Key | Rex behavior |
| --- | --- |
| Ctrl+Shift+T | New tab |
| Ctrl+Shift+W | Close pane |
| Ctrl+Shift+N | New client window |
| Ctrl+Enter | Unbound; passed to terminal applications |
| Shift+Enter | Send ESC followed by CR, matching Ghostty |

On Torrent, Nix also sets TX02 Nerd Font Mono at 13 points, disables copy on
select, keeps Fish as the startup shell, and enables the theme palette. Native
macOS menu equivalents add Ctrl+Shift+C/V for Copy/Paste without replacing
other custom menu equivalents. App restart may be needed for native defaults.

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
Rex Beta Discord membership, not the package token. It is not automatically
installed or authenticated by this aspect.
