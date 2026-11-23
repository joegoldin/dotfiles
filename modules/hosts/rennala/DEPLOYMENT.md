# Rennala deployment

Rennala is the x86_64-linux RackNerd VPS. Its current configuration runs a
**dispatch-disabled Pi Manager acceptance deployment**, a headless desktop,
and the normal managed Pi and Rex profiles. See
[PI_MANAGER.md](PI_MANAGER.md) for authentication, credentials, resource limits,
and acceptance gates.

The previous Happy Server guide is retired. This host no longer declares the
Happy Docker container, PostgreSQL, Redis, or MinIO stack. Do not follow the
old instructions to build a `happy-server:latest` image, create local
`secrets/` files, use ports 3005/3006, or run `deploy-racknerd`.

This guide describes the declarative configuration, not an assertion that it
has been deployed or passed live acceptance.

## Configuration map

| File | Responsibility |
| --- | --- |
| [`default.nix`](default.nix) | Host/user entity, base aspects, disk/hardware imports, and agenix identity path |
| [`system.nix`](system.nix) | BIOS GRUB on `/dev/vda`, key-only SSH with root login disabled, and fail2ban |
| [`machine.nix`](machine.nix) | Tailscale, Docker, SSH firewall rule, and trusted interfaces |
| [`home.nix`](home.nix) | Lean server CLI profile |
| [`pi-manager.nix`](pi-manager.nix) | Application policy/template, credential paths, HTTPS frontend, and limits |
| [`_render-pi-manager.mjs`](_render-pi-manager.mjs) | Runtime policy merge and configuration validation |
| [`_disk-config.nix`](_disk-config.nix) | First-install disk layout; applying it can erase `/dev/vda` |

The reusable application module is imported by
[`modules/ai/pi-manager.nix`](../../ai/pi-manager.nix). Pi's model defaults and
host integration live in [`modules/ai/pi.nix`](../../ai/pi.nix).

## Prerequisites

- GitHub credentials that can fetch the private flake inputs.
- A working SSH connection to the intended host, with a separate recovery path.
- The correct host key, agenix identity, and secret recipients in the private
  `dotfiles-secrets` repository. This configuration decrypts with
  `/home/joe/.ssh/id_rsa`; do not put that key or plaintext credentials in
  this checkout or the Nix store.
- The six Pi Manager credentials and owner policy described in
  [PI_MANAGER.md](PI_MANAGER.md). This generation keeps Pi Manager private on
  Rennala while its state is prepared for migration; it does not need a public
  DNS record or browser proxy.

## Evaluate, then build without activation

Run from the repository root:

```fish
nix eval --raw .#nixosConfigurations.rennala.config.system.build.toplevel.drvPath --option allow-import-from-derivation false
nix build --cores 1 --max-jobs 1 --no-link --print-out-paths .#nixosConfigurations.rennala.config.system.build.toplevel
```

The first command evaluates; the second builds. Neither activates Rennala.
Before switching, compare the proposed closure with the host's current
`/run/current-system` using `nvd diff` and record the old store path as a
rollback reference. Keep a working SSH connection open and review firewall
changes and application acceptance requirements.

The template derives its native Pi version from the locked runtime package.
Still verify the installed executable and the application's protocol support;
see the [version compatibility note](PI_MANAGER.md#native-pi-version-compatibility).
Matching metadata is not a substitute for that application-level check.

## Activate an existing host

Only after build, review, acceptance checks, and deployment authorization:

```fish
just build-to-rennala --local
```

This recipe runs **`nh os switch` on the target**. `--local` builds on the
machine running the command and copies the closure to Rennala; without it,
the recipe builds on Rennala. Both forms activate. The target SSH user and
domain come from the private input's `domains.nix`.

Do not substitute first-install tooling for a routine upgrade. The separate
`just deploy-rennala IP` recipe runs nixos-anywhere against `joe@IP` and uses
the disko configuration. It is for an explicitly authorized first install,
not a non-destructive test or an application redeploy.

A Linux switch may restart the managed personal Rex service and end its
sessions. Save work and keep an independent SSH connection; see the
[Rex service-lifetime guide](../../home/_rex/README.md).

## Network and post-switch checks

The declared public TCP ports are 22 for SSH, 80 for ACME, and 443 for Caddy.
The browser backend binds to `127.0.0.1:8787`; private desktop backends are not
public reverse-proxy targets. `tailscale0` and `docker0` are trusted firewall
interfaces, so do not infer that the public-port allowlist restricts tailnet
or container-bridge access in the same way.

After an authorized switch, inspect on Rennala:

```fish
systemctl status caddy fail2ban
systemctl --user status pi-manager-controller rex
ss -ltn
loginctl show-user joe -p Linger
```

Also verify the private desktop units named by the pinned application module,
the HTTPS certificate and unauthenticated redirects, secret ownership/modes,
and loopback-only backend listeners. Do not print credential contents,
authentication callback URLs, or private desktop URLs into shared logs.

Dispatch must remain disabled until the separate native/protocol, AuthHero
code/PKCE/MFA, denied-identity, mobile/PWA, desktop takeover, installed-Pi GUI,
and loaded-host acceptance gates in `PI_MANAGER.md` pass. Healthy units or a
new model selection are not a waiver of those gates.
