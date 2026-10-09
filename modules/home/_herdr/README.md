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
| Plugins and agents | Can execute commands and access the network as the user. None are installed or registered by this module. The privacy of programs run inside panes is separate from Herdr's own networking. |

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

No Herdr config file is managed here, so existing settings, including history
persistence, are preserved. To disable the two allowed background downloads later,
merge this into `~/.config/herdr/config.toml` and reload the server config:

```toml
[update]
version_check = false
manifest_check = false
```

These switches do not disable explicit update/plugin-install/remote-bootstrap
commands. They are not a network sandbox.

## Validation

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
