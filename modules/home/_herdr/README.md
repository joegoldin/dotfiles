# Herdr

Herdr v0.9.3 is pinned in `flake.lock` and built from source through its upstream
flake. `modules/home/herdr.nix` installs the client and a user-owned background
server wherever the `joe` aspect is used, including lean servers. It opens no
firewall ports. Linux uses a systemd user service with lingering; macOS uses a
Home Manager LaunchAgent, started at login. A small Python supervisor gives the
macOS server its own POSIX session (required by Herdr's remote-attach handshake)
and forwards stop signals. It does not patch the Herdr binary.

## Privacy review

Reviewed the v0.9.3 application networking, configuration, persistence, logging,
local IPC, remote bootstrap, and terminal-library build paths. This is a targeted
source review, not a full dependency audit or a guarantee against vulnerabilities.

| Behavior | Finding and policy |
| --- | --- |
| Release checks | Enabled, as requested. Fetches `https://herdr.dev/latest.json` at startup and periodically. Requests use curl without a session-content payload or application-generated tracking ID. The endpoint still sees ordinary request metadata, including the source IP. Nix installs must update through Nix. |
| Agent-detection updates | Enabled, as requested. Fetches `https://herdr.dev/agent-detection/index.toml` and the rule files it lists. These are downloaded detection rules, not uploaded terminal output. They can change independently of the pinned binary. |
| Analytics/crash uploads | No application analytics SDK or crash-upload path found. Herdr's tracing output goes to local rotating files. The vendored Ghostty source includes Sentry support for the full Ghostty application, but Herdr links the separate terminal library, whose build imports do not include Sentry. Fetching the upstream Zig dependency bundle can nevertheless list Sentry and Breakpad sources. |
| Terminal history | **Unchanged.** Upstream defaults `experimental.pane_history` to false. If the user enables it, `session-history.json` is written beside the local session snapshot on the server machine. No Herdr cloud-sync/upload path found. Local backup/sync software can still copy those files. |
| Session state and logs | Stored locally; may include paths, process information, agent session references, and, if enabled, terminal output. The managed server uses umask 0077. This does not retroactively change permissions on existing files. |
| Client/API access | Owner-only Unix sockets (0600), not a public TCP listener. Processes running as the same user can control panes/read output; Herdr is not a security boundary against those processes or agents. |
| Remote attach | Uses OpenSSH and the user's SSH authentication. Terminal content and explicitly pasted clipboard images can travel to the selected machine/client. If a compatible remote binary is missing, interactive bootstrap can offer to download/install one; decline that offer on Nix-managed hosts and deploy through Nix instead. |
| Plugins and agents | Can execute commands and access the network as the user. The included `herdr-addons` aspect registers the four pinned plugins below. The privacy of programs run inside panes is separate from Herdr's own networking. |

Source anchors at the pinned release:

- [Update defaults](https://github.com/herdrdev/herdr/blob/v0.9.3/src/config/model.rs#L31-L47)
- [Startup checks](https://github.com/herdrdev/herdr/blob/v0.9.3/src/app/mod.rs#L537-L557)
- [Periodic check guards](https://github.com/herdrdev/herdr/blob/v0.9.3/src/app/runtime.rs#L97-L133)
- [Release HTTP requests](https://github.com/herdrdev/herdr/blob/v0.9.3/src/update.rs#L336-L360)
- [Detection-rule HTTP requests](https://github.com/herdrdev/herdr/blob/v0.9.3/src/detect/manifest_update.rs#L509-L559)
- [Local persistence](https://github.com/herdrdev/herdr/blob/v0.9.3/src/persist/io.rs#L10-L73)
- [Local logging](https://github.com/herdrdev/herdr/blob/v0.9.3/src/logging.rs#L1-L31)
- [Socket permissions](https://github.com/herdrdev/herdr/blob/v0.9.3/src/server/socket_paths.rs#L11-L12)
- [Terminal-library imports](https://github.com/herdrdev/herdr/blob/v0.9.3/vendor/libghostty-vt/src/build/GhosttyZig.zig#L107)
- [Remote behavior](https://herdr.dev/docs/persistence-remote/)

Activation merges the managed theme, indicators, toast delivery, and shortcut defaults
into Herdr's config, preserving unrelated settings, comments, history preferences,
and occupied keys. Agent states use distinct symbols rather than color dots.
Background popups are delivered through the terminal (including Ghostty), so desktop
banners depend on the terminal's OS notification permissions and Focus settings.
Sound preferences are unchanged.
It links Nix-built plugins through Herdr's mutable registry without replacing
user-installed entries. Gruvbox uses Ghostty's Dark Hard background and selection
colors rather than Herdr's softer built-in background. To disable the two allowed background downloads later,
merge this into `~/.config/herdr/config.toml` and reload the server config:

```toml
[update]
version_check = false
manifest_check = false
```

These switches do not disable explicit update/plugin-install/remote-bootstrap
commands. They are not a network sandbox.

## Add-ons and integrations

`den.aspects.herdr` includes `herdr-addons`; Joe's universal aspect includes
Herdr. The Pi, Claude, and Codex aspects include dedicated `herdr-pi`,
`herdr-claude`, and `herdr-codex` aspects. Integration assets come from the same
Herdr release as the server, and hooks merge with the existing runtime hooks.

| Component | Version | Behavior reviewed |
| --- | --- | --- |
| Memex and Herdr plugin | 0.27.1 | Indexes local agent transcripts. Local MiniLM embeddings are configured; initial model downloads go to Hugging Face. Remote embeddings can upload transcript text, but are not configured. Web/MCP daemon listeners are not enabled; the explicit web action remains available. Local usage/analytics tables are not telemetry. |
| Auto Title (`kryptamine/herdr-auto-title`) | 0.13.0 | Reads Herdr's Unix socket, local Git metadata and Claude transcripts. No application HTTP/telemetry path found. First startup overwrites existing pane labels, including manually set ones; subsequent manual renames are protected. Restart launches a detached instance that may survive a server stop. |
| Herdr Navigator | 0.3.6 | Local workspace/process/project discovery and explicit SSH/command actions. Release checks use GitHub tag queries; left enabled. Custom quick actions run as the user. |
| TTT and Herdr plugin | 1.7.1 (plugin manifest 0.1.1) | Built through upstream's Nix flake. No application analytics uploader found. Explicit plugin installs, Git operations, PR access and configured language servers can use the network. Its unauthenticated loopback command listener is opt-in (`--listen`); the managed launcher does not enable it. |

Plugin install-time download/build scripts are removed from the packaged manifests;
binaries and runtime tools are Nix store references. Updates go through Nix rather
than in-app installers. Memex's model cache defaults to
`${XDG_CACHE_HOME:-$HOME/.cache}/memex/fastembed`, avoiding writes into the plugin's
read-only directory. Explicit `FASTEMBED_CACHE_DIR` or `HF_HOME` overrides still work.
This is a targeted application-source review, not a complete dependency audit or
network sandbox. Do not treat locally indexed transcripts as non-sensitive data.

Default shortcuts (existing assignments win): `prefix+N` opens Navigator,
`prefix+M` opens Memex, `prefix+E` opens TTT, and `prefix+R` restarts Auto Title.
Plugin startup hooks run at server startup, not when linking a plugin into an
already-running server. Use the Auto Title restart action to start it without
ending existing panes; Memex also indexes on search or its refresh-index action.

## Validation

All four add-on packages and plugin manifests built on aarch64-darwin. Auto Title's
full Go suite and Navigator's 94 tests passed. Navigator's Darwin-only fixture
patch uses `/private/tmp` where upstream assumes `/tmp` is canonical; no tests
are skipped. TTT retains upstream's package-scoped checks, not its full internal
suite. Memex's upstream package disables its download-dependent test suite.

Isolated runtime checks passed for registration, Auto Title restart, Memex
indexing, live Navigator/Memex/TTT panes, and Claude/Codex session hooks over a
mock Unix socket. Synthetic local semantic indexing/search passed, including
search from a read-only Nix-store working directory with the cache wrapper.
The wiring smoke test disabled downloads only in its temporary configuration.
The Pi asset is release-matched; an interactive Pi integration test remains pending.
Seven local configuration-merge/supervisor tests passed. All ten Linux host add-on
configurations and the Mac Home Manager activation derivation evaluated; Linux
binaries and runtime behavior have not been tested here.


The aarch64-darwin Nix build and an isolated runtime smoke test passed: default
config parsing, startup, API ping, owner-only socket permissions, clean shutdown,
and the two expected startup HTTP attempts. The smoke test intercepted curl;
it did not perform a packet-capture audit or test successful manifest downloads.
An actual temporary LaunchAgent passed startup, detached-server capability, and
stop/cleanup checks. The direct LaunchAgent initially failed the detached-server
check; the supervisor fixes that without modifying Herdr.

All ten installed Linux host service/linger configurations evaluated successfully.
The `volcano-manor-installer` image has no `joe` account and is excluded. Linux
runtime behavior and remote SSH attach still need testing after deployment.
Upstream's Nix package disables its Rust test suite; the package build is not a
claim that those tests ran.

Run the supervisor regression tests with:

```fish
python3 modules/home/_herdr/test_launchd.py -v
```

## Operation

Build the package without activating a host:

```fish
nix build .#herdr --no-link
```

Deploy with the repository's normal host rebuilds. On torrent, `just switch`
activates the nix-darwin and Home Manager configuration. A full rebuild can also
activate other pending host changes; inspect that diff before deploying.

After activation:

```fish
herdr
herdr --remote elphael
herdr status server
```

Detach with `ctrl+b q`. The default session stays in the background. Named
sessions are separate servers and are not started by this service.

Linux service management:

```fish
systemctl --user status herdr
systemctl --user stop herdr
systemctl --user start herdr
```

macOS service status:

```fish
launchctl print gui/(id -u)/org.nix-community.home.herdr
```

Stopping or restarting a server ends its pane processes. Session restore is not
process survival. Updating a managed service may restart it during activation;
finish or move important work before rebuilding. macOS LaunchAgents start at
user login, not before login at machine boot.

Before bumping the pinned release, repeat the networking/configuration review.
The current policy allows update checks and rule downloads, not arbitrary new
telemetry.
