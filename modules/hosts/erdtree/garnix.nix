# Self-hosted garnix CI. Backend :8321, frontend :3000, postgres :9178,
# opensearch :9200 — all localhost; Caddy fronts the app + cache domains.
# Secrets: agenix files installed at /run/secrets/<name> (the backend's
# built-in fallback paths). Design: docs/plans/2026-07-10-garnix-self-hosting-design.md
{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.erdtree.nixos =
    { config, lib, pkgs, ... }:
    let
      domains = import "${dotfiles-secrets}/domains.nix";
      garnixData = import "${dotfiles-secrets}/garnix.nix";
      keys = import "${dotfiles-secrets}/keys.nix";
      dbFqdn = "garnix-db.internal";
      # The Next.js frontend build ships static assets (JS/CSS/fonts) under
      # `${frontendPkg}/public/_next/static`; the standalone server on :3000 does
      # NOT serve them (upstream nginx served them from disk). Caddy serves
      # /_next/* from this path so the SPA actually loads.
      frontendPkg = inputs.garnix-ci.packages.x86_64-linux.frontend_default;
      # Static mirror of garnix.io/docs, served ungated at /docs so the
      # self-hosted app's doc links stay on-domain. Layout: ${docsRoot}/docs/**
      # (pages as .../index.html; assets rewritten to absolute /docs/_next,
      # /docs/images, /docs/favicon.ico so they never collide with the
      # frontend's own /_next/* handler). Refresh via the dotfiles-assets input.
      docsRoot = "${inputs.dotfiles-assets}/garnix-docs";
      # agenix file -> /run/secrets/<name>. Everything owned by garnix:garnix 0440
      # except noted; postgres/systemd read via root LoadCredential.
      garnixSecrets = {
        "database-password" = "garnix-database-password.age";
        "database-monitoring-pgpass" = "garnix-database-monitoring-pgpass.age";
        "github_webhook_secret" = "garnix-github-webhook-secret.age";
        "github_client_id" = "garnix-github-client-id.age";
        "github_client_secret" = "garnix-github-client-secret.age";
        "github_app_id" = "garnix-github-app-id.age";
        "github_app_pk" = "garnix-github-app-pk.age";
        "garnix-jwt-key" = "garnix-jwt-key.age";
        "garnix_server_remote_builder_ssh" = "garnix-remote-builder-ssh.age";
        "garnix_server_ssh_hosting" = "garnix-hosting-ssh.age";
        "garnix_action_runner_ssh" = "garnix-action-runner-ssh.age";
        "repo-secrets-key" = "garnix-repo-secrets-key.age";
        "repo-secrets-key-pub" = "garnix-repo-secrets-key-pub.age";
        "opensearch-garnix" = "garnix-opensearch-password.age";
        "cache-priv-key" = "garnix-cache-priv-key.age";
        "s3-cache-access-key-id" = "garnix-s3-access-key-id.age";
        "s3-cache-secret-access-key" = "garnix-s3-secret-access-key.age";
        "s3-cache-private-access-key-id" = "garnix-s3-private-access-key-id.age";
        "s3-cache-private-secret-access-key" = "garnix-s3-private-secret-access-key.age";
        "s3-artifacts-public-access-key-id" = "garnix-s3-artifacts-public-access-key-id.age";
        "s3-artifacts-public-secret-access-key" = "garnix-s3-artifacts-public-secret-access-key.age";
        "s3-artifacts-private-access-key-id" = "garnix-s3-artifacts-private-access-key-id.age";
        "s3-artifacts-private-secret-access-key" = "garnix-s3-artifacts-private-secret-access-key.age";
        # Gitea forge integration: bot API token + webhook HMAC secret. The
        # backend reads /run/secrets/gitea-token + /run/secrets/gitea-webhook-secret.
        "gitea-token" = "garnix-gitea-token.age";
        "gitea-webhook-secret" = "garnix-gitea-webhook-secret.age";
      };
      # Self-minted CA + cert for postgres TLS (verify-full against dbFqdn).
      # Generated at runtime into /var/lib/garnix-db-certs, NOT the nix store
      # (CI builds untrusted code; the store is world-readable).
      mkDbCerts = pkgs.writeShellScript "mk-garnix-db-certs" ''
        set -euo pipefail
        dir=/var/lib/garnix-db-certs
        if [ ! -f "$dir/${dbFqdn}/cert.pem" ]; then
          mkdir -p "$dir" && cd "$dir"
          ${lib.getExe pkgs.minica} -domains ${dbFqdn}
          mv minica.pem ca.pem
        fi
        chmod 755 "$dir" "$dir/${dbFqdn}"
        chmod 644 "$dir/ca.pem" "$dir/${dbFqdn}/cert.pem"
        chown postgres:postgres "$dir/${dbFqdn}/key.pem"
        chmod 600 "$dir/${dbFqdn}/key.pem"
      '';
    in
    {
      # NOTE (den + specialArgs): `nixosModules.self-hosted` dereferences
      # `flakeInputs` inside its `imports` (for the sops-nix module), which
      # requires flakeInputs via specialArgs — but den assembles specialArgs
      # itself (specialArgs.inputs = the dotfiles inputs) and there's no clean
      # per-aspect specialArgs hook. So we DON'T import the curated module;
      # instead import the fork's modules directly (their `flakeInputs` uses are
      # all in `config`, satisfiable via `_module.args`), and import sops-nix as
      # a static value from the fork's own inputs. Same module set as
      # nixosModules.self-hosted; see that file's header for the contract.
      imports = [
        inputs.garnix-ci.inputs.sops-nix.nixosModules.sops
        # Phase 2 microVM hosting: the fork's provisioner module needs the
        # microvm.nix host module (microvm CLI + microvm@ service template)
        # imported by the consumer — the fork itself stays input-free.
        "${inputs.garnix-ci}/provisioner/nixos-module.nix"
        inputs.microvm-nix.nixosModules.host
        "${inputs.garnix-ci}/backend/nixos-module.nix"
        "${inputs.garnix-ci}/opensearch/nixos-module.nix"
        "${inputs.garnix-ci}/nix/modules/custom-gc.nix"
        "${inputs.garnix-ci}/nix/modules/database.nix"
        "${inputs.garnix-ci}/nix/modules/dev-mode.nix"
        "${inputs.garnix-ci}/nix/modules/fluent-bit.nix"
        "${inputs.garnix-ci}/nix/modules/monitoring-client.nix"
        # Runs repo `actions` locally in a bubblewrap sandbox (self-host has no
        # separate runner fleet); the backend SSHes to action-runner@127.0.0.1.
        "${inputs.garnix-ci}/nix/modules/action-runner.nix"
        # Option stubs that self-hosted.nix normally provides in place of the
        # excluded linux-common.nix (which declares these). Types copied verbatim
        # from nix/modules/self-hosted.nix; defaults null/false are correct
        # (dev-mode.nix only sets ipv4/ipv6Address when devMode.enable, which is off).
        ({ lib, ... }: {
          options.garnix = {
            killRogueNixProcesses = lib.mkOption { type = lib.types.bool; default = false; };
            ipv4 = lib.mkOption {
              default = null;
              type = lib.types.nullOr (lib.types.submodule {
                options = {
                  address = lib.mkOption { type = lib.types.str; };
                  gateway = lib.mkOption { type = lib.types.str; };
                  iface = lib.mkOption { type = lib.types.str; };
                };
              });
            };
            ipv6Address = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
          };
        })
      ];
      # The opensearch module defaults `package = pkgs.opensearch-dashboards`,
      # which only exists via the fork's overlay. Apply it host-wide.
      nixpkgs.overlays = [
        inputs.garnix-ci.overlays.default
        # The fork's opensearch module pins opensearch 2.12.0 by overriding only
        # `version` + `src`, inheriting nixpkgs' installPhase. Current nixpkgs
        # (26.05) ships pkgs.opensearch 3.x, whose installPhase copies an `agent/`
        # dir that exists only in 3.x tarballs; the pinned 2.12.0 tarball lacks it,
        # so `cp -R ... agent` fails the build. Drop `agent` from the copy so the
        # 2.12.0 pin builds — this restores exactly the file set the fork's own
        # (older-nixpkgs) opensearch installPhase copied. No-op if the string ever
        # changes upstream. Mirrors the fork's own installPhase-patch overlay.
        (final: prev: {
          opensearch = prev.opensearch.overrideAttrs (old: {
            installPhase = builtins.replaceStrings
              [ "cp -R bin config lib modules plugins agent $out" ]
              [ "cp -R bin config lib modules plugins $out" ]
              old.installPhase;
          });
        })
      ];

      _module.args.flakePackages = inputs.garnix-ci.packages.x86_64-linux;
      _module.args.flakeInputs = inputs.garnix-ci.inputs;
      # monitoring-client needs garnix.monitoring.monitoredHosts (from the
      # excluded monitoring.nix); keep it OFF so that option is never demanded.
      garnix.monitoring-client.enable = false;

      age.secrets = (lib.mapAttrs'
        (name: file: lib.nameValuePair "garnix-${name}" {
          file = "${dotfiles-secrets}/${file}";
          path = "/run/secrets/${name}";
          symlink = false;
          owner = "garnix";
          group = "garnix";
          # SSH private keys the backend (garnix user) uses as an ssh identity —
          # into guest microVMs (hosting key) and into the local action-runner
          # user (action-runner key). OpenSSH refuses a private key that is
          # group-readable when the caller owns it, so these must be 0400 (not
          # the blanket 0440 the other garnix secrets use).
          mode =
            if name == "garnix_server_ssh_hosting" || name == "garnix_action_runner_ssh"
            then "0400"
            else "0440";
        })
        garnixSecrets)
      // {
        # oauth2-proxy env file (OAUTH2_PROXY_CLIENT_SECRET + cookie secret);
        # read by systemd as root via EnvironmentFile, so default agenix
        # root:root 0400 is correct. Declared here (not as a sibling
        # `age.secrets.* = …`) because `age.secrets` is already a non-literal
        # `//`-merge, and Nix can't merge a nested path into that.
        garnix-oauth2-proxy-env.file = "${dotfiles-secrets}/garnix-oauth2-proxy-env.age";
        # garnix builds substitute from attic: the sandbox binds the combined
        # netrc (attic + garnix cache, declared in attic-cache.nix), which must
        # be readable by the garnix service user — agenix defaults to
        # root:root 0400. Declared here for the same `//`-merge reason.
        attic-netrc = {
          mode = "0440";
          group = "garnix";
        };
      };

      networking.hosts."127.0.0.1" = [ dbFqdn ];

      garnix = {
        manageSecretsWithSops = false;
        devMode.enable = false;
        fluent-bit = {
          enable = true;
          extraGroups = [ "garnix" ]; # read opensearch password file
          opensearch = {
            fqdn = "localhost";
            port = 9200;
            tls = false;
            basicAuth = {
              username = "garnix";
              passwordFile = "/run/secrets/opensearch-garnix";
            };
          };
        };
        opensearch = {
          enable = true;
          fqdn = "localhost";
          isSingleNode = true;
          exposeViaNginx = false;
          heapSize = 4096;
        };
        database = {
          enable = true;
          fqdn = dbFqdn;
          certDir = "/var/lib/garnix-db-certs/${dbFqdn}";
          ssl.rootCert = "/var/lib/garnix-db-certs/ca.pem";
          zfsSnapshots = false;
          allowedIPs = [ ]; # localhost only; pg_hba local rules suffice
        };
      };

      # Host metrics for the self-host Monitoring page (loopback only; the
      # garnix backend scrapes 127.0.0.1:9100).
      services.prometheus.exporters.node = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9100;
        enabledCollectors = [ "systemd" ];
      };

      services.garnixServer = {
        enable = true;
        url = "https://${domains.garnixDomain}";
        githubAppName = garnixData.github.appName; # slug from the app-manifest bootstrap
        selfHostMode = true;
        adminGroup = garnixData.authentik.adminGroup;
        # Second forge: our self-hosted Gitea. Enables the /api/events/gitea
        # webhook (Caddy @webhook bypass added above) + Gitea commit-status
        # reporting; token/secret via the gitea-* agenix secrets.
        giteaUrl = "https://${domains.giteaDomain}";
        # Publish modules from our own org's repos (the 7 forked + 3 authored
        # module repos live under joegoldin). Upstream default is "garnix-io".
        modulesOrg = "joegoldin";
        opensearchUrl = "http://[::1]:9200/_msearch";
        cacheUrl = "https://${domains.garnixCacheDomain}";
        cachePublicKey = garnixData.cachePublicKey;
        enableNginx = false;
        journaldMaxUse = "10G";
        # nix `max-jobs` for local derivation builds; the nix-daemon cgroup caps
        # below bound the actual CPU/RAM they can consume.
        maxLocalJobs = 8;
        # How many garnix builds eval+run at once. Every build still fans out and
        # shows pending immediately; the rest queue behind this cap (round-robin
        # fair by repo owner) and flip to running as slots free. Keeps a big
        # multi-commit push from spawning dozens of guests and drowning the
        # fluent-bit log pipeline. 16 of erdtree's 32 threads.
        maxConcurrentBuilds = 16;
        # Authenticate sandboxed evals/builds to attic (and the garnix cache)
        # so substitution works inside the bubblewrap sandbox — the sandbox
        # can't read the host nix.conf's netrc path unless it's bound in and
        # readable by the garnix user (see age.secrets.attic-netrc below).
        buildNetRcFile = config.age.secrets.attic-netrc.path;
        # Native aarch64 builder (farum-azula, Ampere) so garnix stops emulating
        # aarch64 configs (farum-azula, scarab) via qemu — 10-50x faster. The
        # nix-daemon (root) SSHes as nix-ssh with the remote-builder key; the
        # known-hosts entry below lets it verify the host non-interactively.
        buildMachines = [
          {
            hostName = "farum-azula-builder";
            hostAddress = domains.farumAzulaDomain;
            systems = [ "aarch64-linux" ];
            maxJobs = 1; # 2-core box shared with game servers
            speedFactor = 2; # native >> emulation
            supportedFeatures = [ "big-parallel" ];
          }
        ];
        # backend/nixos-module.nix hardcodes garnix.io's R2 fleet values
        # (host/buckets/baseUrl) at NORMAL priority in both dev/prod branches —
        # Task 3 parameterized only the cache *domain*, not the S3 bucket config.
        # mkForce is required (and is what the eval error recommends) to point
        # the self-host cache at our own B2 buckets.
        s3Cache = lib.mkForce {
          publicBucket = garnixData.b2.publicBucket;
          publicBaseUrl = garnixData.b2.publicBaseUrl;
          privateBucket = garnixData.b2.privateBucket;
          host = garnixData.b2.endpoint;
          region = garnixData.b2.region;
        };
        # Build artifacts (garnix.yaml `artifacts:`): two dedicated B2 buckets,
        # routed public/private by the same repo-publicity rules as the cache.
        # Host/region reuse the s3Cache values; key pairs come from the four
        # s3-artifacts-* agenix secrets above.
        s3Artifacts = {
          publicBucket = garnixData.b2.artifactsPublicBucket;
          privateBucket = garnixData.b2.artifactsPrivateBucket;
          publicBaseUrl = garnixData.b2.artifactsPublicBaseUrl;
        };
        # Phase 2 microVM hosting: branch deployments become local microVMs
        # (LocalProvisioner talks to garnix-provisionerd over this socket) at
        # <pkg>.<branch>.<repo>.<owner>.<hostingDomain>. provisionServerPool
        # keeps the pool pre-warmed (self-host default: one i2x4 guest).
        hostingDomain = domains.garnixAppsDomain;
        provisionerSocket = "/run/garnix-provisioner/provisioner.sock";
        provisionServerPool = true;
        # External SSH host the Servers page uses to build the ssh command for a
        # deployed server's DNAT'd port (garnix.yaml sshExpose) and the ProxyJump
        # into the guest subnet.
        sshHost = domains.erdtreeSshDomain;
        # Repo `actions` run on the local action-runner user (garnix.actionRunner
        # below): the backend `nix copy`s the closure to action-runner@127.0.0.1
        # and executes it in a bwrap sandbox there.
        actionHost = "127.0.0.1";
        # Monitoring page scrape targets (node-exporter on loopback; garnix's own
        # Prometheus defaults to 127.0.0.1:<metricsPort>).
        nodeExporterUrl = "http://127.0.0.1:9100/metrics";
      };

      # Trust farum-azula's host key so the remote-builder ssh (as root, batch
      # mode) verifies it without an interactive prompt. keys.farum-azula is the
      # machine's ed25519 host key (also its agenix recipient).
      programs.ssh.knownHosts."farum-azula-builder" = {
        hostNames = [ "farum-azula-builder" domains.farumAzulaDomain "147.224.12.5" ];
        publicKey = keys.farum-azula;
      };

      # erdtree is the builder: allow emulated aarch64 + the features garnix schedules.
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      nix.settings = {
        extra-platforms = [ "aarch64-linux" ];
        experimental-features = [ "nix-command" "flakes" "recursive-nix" ];
        system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" "recursive-nix" ];
        trusted-users = [ "garnix" ];
        # Half the box per derivation: erdtree is a dual E5-2667 v2 = 32
        # threads, so a single build (ghc, rustc, …) may use up to 16. Total
        # build CPU/RAM is capped by the nix-daemon cgroup below. (mkForce: the
        # garnix module hardcodes cores = 4.)
        cores = lib.mkForce 16;
      };

      # CI must not starve the machine (it's also a gaming/HPC box): cap the
      # cgroups where build work actually runs to ~half of 32 threads / 251G.
      #  - nix-daemon: the actual derivation builds (ghc/rustc/… as nixbld*)
      #  - garnixServer: sandboxed evals, nar packing, cache uploads
      systemd.services.nix-daemon.serviceConfig = {
        CPUQuota = "1600%"; # 16 of 32 threads
        MemoryHigh = "115G"; # throttle before the hard cap
        MemoryMax = "125G"; # half of 251G
      };

      # The garnix database module sets enableTCPIP (listen_addresses = "*"),
      # binding postgres to 0.0.0.0. Only the local backend connects (over
      # loopback via garnix-db.internal → 127.0.0.1), so pin it to loopback so
      # nothing on the hosting bridge / network can reach the CI database.
      services.postgresql.settings.listen_addresses = lib.mkForce "localhost";

      # DB certs before postgres; secrets before the services that read them.
      systemd.services.postgresql.serviceConfig.ExecStartPre = lib.mkBefore [ "+${mkDbCerts}" ];
      systemd.services.garnixServer = {
        after = [ "agenix.service" "postgresql.service" "opensearch.service" ];
        wants = [ "agenix.service" ];
        serviceConfig = {
          MemoryHigh = "48G";
          MemoryMax = "64G";
        };
      };
      systemd.services.opensearch.serviceConfig.MemoryHigh = "8G";
      systemd.services.frontend = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
      };

      # oauth2-proxy: OIDC client against Authentik; Caddy forward_auths to it.
      # ACCESS GATE = Authentik application *entitlements* (like gitea), enforced
      # here by `allowed-group`: a custom Authentik scope mapping synthesizes an
      # OIDC `groups` claim from the user's entitlements (garnixadmin ->
      # "garnix-admins", garnixuser -> "garnix-users"); a user with NO garnix
      # entitlement gets no allowed group and is 403'd at the proxy. The
      # synthesized claim then flows to the backend via X-Auth-Request-Groups
      # (Task 5b header trust), where "garnix-admins" -> subscription_type=admin.
      # (The env-file secret `garnix-oauth2-proxy-env` is declared in the
      # `age.secrets` block above alongside the other garnix secrets.)
      services.oauth2-proxy = {
        enable = true;
        provider = "oidc";
        clientID = garnixData.authentik.clientId;
        oidcIssuerUrl = garnixData.authentik.issuerUrl;
        redirectURL = "https://${domains.garnixDomain}/oauth2/callback";
        scope = garnixData.authentik.scope;   # "openid profile email garnix"
        reverseProxy = true;
        # Only local Caddy forward_auths to the proxy; trust its X-Forwarded-*
        # headers from loopback only (else oauth2-proxy trusts all source IPs —
        # a spoofing risk the module warns about, and one that would undermine
        # the X-Auth-Request-* header-trust model).
        trustedProxyIP = [ "127.0.0.1/32" "::1/128" ];
        setXauthrequest = true;
        httpAddress = "127.0.0.1:4180";
        email.domains = [ "*" ];
        cookie.secure = true;
        keyFile = config.age.secrets.garnix-oauth2-proxy-env.path;
        extraConfig = {
          skip-provider-button = true;
          cookie-refresh = "50m";
          # oidc-groups-claim defaults to "groups" (what the mapping returns).
          # allowed-group is the entitlement gate; repeatable flag -> list value.
          allowed-group = garnixData.authentik.allowedGroups;
          # Authentik issues id_tokens with email_verified=false for accounts
          # that never went through an email-verification flow; oauth2-proxy
          # rejects those by default (500 on /oauth2/callback). We fully trust
          # this IdP (single-tenant, self-hosted), so accept unverified emails.
          insecure-oidc-allow-unverified-email = true;
          # Caddy forward_auth builds an absolute rd=https://<host>/... redirect;
          # oauth2-proxy only honors post-login redirects to whitelisted domains,
          # else it drops them. Whitelist our own app domain (repeatable flag).
          whitelist-domain = [ domains.garnixDomain ];
        };
      };
      systemd.services.oauth2-proxy = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
      };

      # ── Phase 2: microVM hosting infrastructure ─────────────────────────────
      # garnix-provisionerd (fork provisioner module) creates guests on the
      # garnixbr0 bridge; the microvm.nix host module supplies the microvm CLI
      # + microvm@ template it drives.
      microvm.host.enable = true;
      garnix.local-provisioner = {
        enable = true;
        # erdtree's uplink (`ip route show default` -> dev eno1); guests NAT
        # out through it.
        uplinkInterface = "eno1";
        # Store-path flakerefs: the per-VM flakes pin to the host's own inputs
        # so guest builds need no network fetch.
        nixpkgsFlake = "path:${inputs.nixpkgs}";
        microvmFlake = "path:${inputs.microvm-nix}";
        # Guests push their CPU/RAM samples here (bridge NAT -> public garnix
        # API, same path guests already use for /api/keys/*). The @stats Caddy
        # bypass below lets the unauthenticated POST through the Authentik gate.
        statsReportUrl = "https://${domains.garnixDomain}/api/hosts/stats";
      };
      # The daemon's ExecStartPre derives the guest pubkey from the
      # agenix-installed hosting key; order it after secrets exist.
      systemd.services.garnix-provisionerd = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
      };

      # ── Action runner ───────────────────────────────────────────────────────
      # Repo `actions` execute here, isolated in a bubblewrap sandbox. The
      # backend connects as action-runner@127.0.0.1 with the
      # garnix_action_runner_ssh key; sshPrivateKeyPath makes the runner
      # authorize exactly that key's pubkey (derived at boot).
      garnix.actionRunner = {
        enable = true;
        sshPrivateKeyPath = "/run/secrets/garnix_action_runner_ssh";
      };
      # The authorized-key derivation reads the agenix-installed private key;
      # order it after secrets exist.
      systemd.services.garnix-action-runner-authorized-key = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
      };

      # Traefik routes app domains to guest IPs, polling the backend's
      # dynamic-config endpoint. Loopback plain HTTP; Caddy terminates TLS in
      # front. The backend tags every router with the `heartbeatmiddleware`
      # plugin, so we load it as a Yaegi local plugin (same as upstream's
      # hosting-gateway) — otherwise Traefik would error every router. The
      # plugin only records seen hosts + POSTs them to /api/hosts/heartbeat in a
      # background goroutine; with the self-host reaper disabled those reports
      # are harmless (and the POST 401s at the auth gate), but loading it keeps
      # routing valid with zero backend divergence.
      services.traefik = {
        enable = true;
        staticConfigOptions = {
          entryPoints.web.address = "127.0.0.1:8090";
          providers.http = {
            endpoint = "http://127.0.0.1:8321/api/hosts/traefik";
            pollInterval = "5s";
          };
          experimental.localPlugins.heartbeatmiddleware.moduleName =
            "github.com/garnix-io/garnix/heartbeatmiddleware";
        };
      };
      # Yaegi loads local plugins from <workdir>/plugins-local/src/<moduleName>;
      # stage the fork's plugin source there before Traefik starts.
      systemd.services.traefik.serviceConfig.ExecStartPre = [
        (pkgs.writeShellScript "init-traefik-heartbeat-plugin" ''
          set -eu
          dst=/var/lib/traefik/plugins-local/src/github.com/garnix-io/garnix
          # The source is copied from the read-only nix store, so a prior copy
          # leaves read-only dirs that `rm -rf` can't descend into. Make the
          # tree writable first, and writable again after copying, so this stays
          # idempotent across redeploys/restarts.
          [ -e "$dst" ] && chmod -R u+w "$dst"
          rm -rf "$dst"
          mkdir -p "$dst"
          cp -r ${inputs.garnix-ci}/hosting-gateway/heartbeatmiddleware "$dst/heartbeatmiddleware"
          chmod -R u+w "$dst"
        '')
      ];

      # On-demand TLS: before issuing a per-SNI cert, Caddy asks the backend
      # whether the domain belongs to a currently-deployed server. Deployed
      # domains sit 2 or 4 labels below the apps domain and Caddy site
      # wildcards only match one label, so a catch-all HTTPS site (gated by
      # the ask endpoint) handles them instead of a *.apps.<domain> block.
      services.caddy.globalConfig = ''
        on_demand_tls {
          ask http://127.0.0.1:8321/api/hosts/on-demand-check
        }
      '';

      # Caddy front (Caddy already enabled by wings.nix; 80/443 already open).
      # Webhooks bypass the auth gate (GitHub posts there, HMAC-verified);
      # everything else on the app domain requires an Authentik session.
      services.caddy.virtualHosts = {
        # Deployed-server app domains (any depth under apps.<domain>): per-SNI
        # on-demand certs, then straight to Traefik. Unknown SNI never gets a
        # cert (the ask endpoint 404s), so the catch-all is issuance-gated.
        "https://".extraConfig = ''
          tls {
            on_demand
          }
          reverse_proxy 127.0.0.1:8090
        '';
        # The apps apex itself (not covered by the *.apps DNS wildcard or the
        # on-demand gate): normal managed cert; Traefik 404s unknown hosts.
        "https://${domains.garnixAppsDomain}".extraConfig = ''
          reverse_proxy 127.0.0.1:8090
        '';
        "${domains.garnixDomain}".extraConfig = ''
          # Never trust client-supplied auth headers; only forward_auth sets them.
          request_header -X-Auth-Request-User
          request_header -X-Auth-Request-Email
          request_header -X-Auth-Request-Groups
          @webhook path /api/events/github/* /api/events/gitea /api/events/gitea/*
          handle @webhook {
            reverse_proxy 127.0.0.1:8321
          }
          # Public-key endpoints: /api/keys/<owner>/<repo>/repo-key.public and
          # /api/keys/<owner>/<repo>/actions/<action>/key.public. These backend
          # routes carry no auth by design — the authentik-provision helper and
          # provisioned guests fetch them unauthenticated to encrypt secrets to
          # the repo key. Bypass the Authentik gate (public keys only: they can
          # encrypt but not decrypt, and expose no private data).
          @publickeys path /api/keys/*
          handle @publickeys {
            reverse_proxy 127.0.0.1:8321
          }
          # Status badges (/api/badges/<owner>/<repo>): public by design so they
          # render in READMEs for anonymous viewers. No auth on the backend
          # route; bypass the Authentik gate.
          @badges path /api/badges/*
          handle @badges {
            reverse_proxy 127.0.0.1:8321
          }
          # Artifact downloads: scripts fetch with garnix access tokens, so they must
          # bypass the Authentik gate; the backend enforces session-or-token auth and
          # repo access itself (public artifacts are anonymous by design).
          @artifacts path /api/artifacts/*
          handle @artifacts {
            reverse_proxy 127.0.0.1:8321
          }
          # Per-server resource stats: deployed microVM guests POST their
          # CPU/RAM samples here unauthenticated (like the heartbeat / public-key
          # routes), so bypass the Authentik gate. The backend just records the
          # sample and drops any that don't map to a live server.
          @stats path /api/hosts/stats
          handle @stats {
            reverse_proxy 127.0.0.1:8321
          }
          handle /oauth2/* {
            reverse_proxy 127.0.0.1:4180
          }
          # Next.js static assets: served from disk (the :3000 standalone server
          # doesn't). Ungated — client-side JS/CSS/fonts are inherently public,
          # and gating them would break on the 401->redirect-returns-HTML path.
          handle /_next/* {
            root * ${frontendPkg}/public
            file_server
          }
          # Mirrored garnix docs (static HTML). Ungated public docs, same as
          # /_next above. Pages live at ${docsRoot}/docs/<slug>/index.html and
          # reference their assets via absolute /docs/_next|images|favicon
          # paths, so this single handle serves pages + assets. try_files
          # resolves trailing-slash, no-slash, and .html forms, falling back to
          # the docs index for anything missing (graceful 404).
          handle /docs* {
            root * ${docsRoot}
            try_files {path} {path}index.html {path}/index.html {path}.html /docs/index.html
            file_server
          }
          handle {
            forward_auth 127.0.0.1:4180 {
              uri /oauth2/auth
              copy_headers X-Auth-Request-User X-Auth-Request-Email X-Auth-Request-Groups
              @error status 401
              handle_response @error {
                redir * /oauth2/start?rd={scheme}://{host}{uri}
              }
            }
            @api path /api/*
            reverse_proxy @api 127.0.0.1:8321
            reverse_proxy 127.0.0.1:3000
          }
        '';
        "${domains.garnixCacheDomain}".extraConfig = ''
          # Never trust client-supplied auth headers on any garnix vhost.
          request_header -X-Auth-Request-User
          request_header -X-Auth-Request-Email
          request_header -X-Auth-Request-Groups
          # Nix queries the substituter root (/nix-cache-info, /<hash>.narinfo); the
          # backend serves the cache under /api/cache/. Rewrite so ONLY the cache
          # surface is reachable here (login/API paths become /api/cache/... -> 404).
          rewrite * /api/cache{uri}
          reverse_proxy 127.0.0.1:8321
        '';
      };
    };
}
