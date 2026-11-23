# Pi Manager acceptance deployment

Rennala owns the native controller, the normal Home Manager Pi profile and a
persistent headless KDE X11 session. The application comes from the private
`pi-manager-agent` flake input. `flake.lock` pins a revision of its `main`
branch. This host configuration is an acceptance deployment, not a production
release or a waiver of application acceptance gates.

`modules/ai/pi-manager.nix` imports the reusable application module and the
existing Pi aspect. `pi-manager.nix` here owns host policy, resource limits,
secret paths and HTTPS routing. Nothing installs Pi or systemd units by hand.

## Boundaries

- Dispatch is disabled. The supervisor and worker grants are read-only. Enabling
  work requires a reviewed policy change after the remaining native, provider
  and device acceptance checks.
- The migration configuration removes the public Caddy site and its HTTP/HTTPS
  firewall ports. SSH on TCP 22 remains configured in `machine.nix`. The
  dispatch-disabled browser service listens only on IPv4 loopback port 8787
  while its state is prepared for migration. No browser proxy is configured.
- The application verifies the signed AuthHero login and exact configured owner
  subject. AuthHero owns the application's MFA policy; explicit requested assurance
  remains enforced, and sensitive operations require a fresh login. The
  application refuses forwarding-based authentication.
- Six encrypted files in the existing private `dotfiles-secrets` input supply
  the AuthHero client secret, distinct native and browser-session keys, the
  Guacamole JSON key, VNC password and exact-owner browser policy. Recipients
  are your recovery identity and Rennala, not the fleet. Agenix supplies owned
  mode-0400 files; the application module stages independent runtime copies.
- The owner policy is merged with the immutable path-only deployment template
  immediately before startup. The renderer validates the full application
  schema, requires a canonical owned mode-0700 runtime directory and atomically
  writes a mode-0400 configuration. Neither owner subjects nor credential values
  are embedded in the Nix store template.
- At most one worker is active or resident. Each worker has a 768 MiB memory
  limit, 128 tasks and 50% CPU. The controller has 384 MiB and 50% CPU;
  Guacamole has 512 MiB and guacd 128 MiB. These are limits, not evidence that
  the host passes loaded-capacity acceptance.
- No public ingress bridge, provider integration, live voice call or SMS is
  enabled by this initial deployment. The independent ingress role must remain
  on a separately selected host; it must not become a native-host dependency.

## Native Pi version compatibility

The controller template in [`pi-manager.nix`](pi-manager.nix) derives
`core.pi.version` from the locked agent-skills → pi-nix `coding-agent-bun`
package, currently Pi 1.5.2, instead of maintaining a separate version literal.
The `checks.x86_64-linux.pi-manager-template` check also executes the actual
Home Manager installed wrapper in a fresh sandbox home, compares its `--version`
with the serialized template, and keeps dispatch disabled. Metadata agreement
alone is not enough when a profile overrides the runtime.

Keep the system template and user profile in sync when upgrading Pi. The controller
intentionally refuses to start if their versions differ; do not bypass that guard
or substitute the observed runtime version into an unreviewed configuration.

The managed Pi profile defaults to `openai/gpt-6.2-sol`, with 6.2 Astra also
available. Model choice is separate from native runtime compatibility.
Check the pinned application's version/protocol requirements against the
installed executable before deployment or dispatch enablement. Matching
version metadata and successful Nix evaluation do not prove the full native
protocol or waive any acceptance gate.

## Build before switching

From this dotfiles checkout, evaluate and build without activation:

```fish
nix eval --raw .#nixosConfigurations.rennala.config.system.build.toplevel.drvPath --option allow-import-from-derivation false
nix build --cores 1 --max-jobs 1 --no-link --print-out-paths .#nixosConfigurations.rennala.config.system.build.toplevel
```

Inspect the closure difference against Rennala's current `/run/current-system`
and record that old store path as the rollback reference. Preserve a working
SSH connection and verify that the proposed firewall still permits SSH before
switching.

The existing activation command is:

```fish
just build-to-rennala --local
```

Despite its name, this command runs `nh os switch`: it activates the host. It is
not a build-only probe. Use it only after the build and required checks pass and
activation is authorized. Do not use a local application-input override for
activation.

After switching, check the installed Pi version/native protocol, controller and
private desktop units, HTTPS certificate, unauthenticated redirects, secret
permissions and loopback-only backend listeners. Human AuthHero code/PKCE/MFA,
a denied valid identity, intended mobile/PWA use, exact desktop takeover,
installed-Pi GUI work and loaded-host behavior remain separate acceptance
checks. A healthy service or version probe does not prove them.

For host layout, first-install warnings, and routine upgrade steps, see
[DEPLOYMENT.md](DEPLOYMENT.md).
