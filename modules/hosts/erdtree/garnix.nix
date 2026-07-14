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
        "hetzner-token" = "garnix-hetzner-token.age";
        "cache-priv-key" = "garnix-cache-priv-key.age";
        "s3-cache-access-key-id" = "garnix-s3-access-key-id.age";
        "s3-cache-secret-access-key" = "garnix-s3-secret-access-key.age";
        "s3-cache-private-access-key-id" = "garnix-s3-private-access-key-id.age";
        "s3-cache-private-secret-access-key" = "garnix-s3-private-secret-access-key.age";
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
        "${inputs.garnix-ci}/backend/nixos-module.nix"
        "${inputs.garnix-ci}/opensearch/nixos-module.nix"
        "${inputs.garnix-ci}/nix/modules/custom-gc.nix"
        "${inputs.garnix-ci}/nix/modules/database.nix"
        "${inputs.garnix-ci}/nix/modules/dev-mode.nix"
        "${inputs.garnix-ci}/nix/modules/fluent-bit.nix"
        "${inputs.garnix-ci}/nix/modules/monitoring-client.nix"
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
          mode = "0440";
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

      services.garnixServer = {
        enable = true;
        url = "https://${domains.garnixDomain}";
        githubAppName = garnixData.github.appName; # slug from the app-manifest bootstrap
        selfHostMode = true;
        adminGroup = garnixData.authentik.adminGroup;
        # Publish modules from our own org's repos (the 7 forked + 3 authored
        # module repos live under joegoldin). Upstream default is "garnix-io".
        modulesOrg = "joegoldin";
        opensearchUrl = "http://[::1]:9200/_msearch";
        cacheUrl = "https://${domains.garnixCacheDomain}";
        cachePublicKey = garnixData.cachePublicKey;
        enableNginx = false;
        journaldMaxUse = "10G";
        # Half the box (20 threads): garnix schedules at most this many
        # concurrent package builds; the nix-daemon cgroup caps below bound the
        # actual CPU/RAM they can consume.
        maxLocalJobs = 8;
        # Authenticate sandboxed evals/builds to attic (and the garnix cache)
        # so substitution works inside the bubblewrap sandbox — the sandbox
        # can't read the host nix.conf's netrc path unless it's bound in and
        # readable by the garnix user (see age.secrets.attic-netrc below).
        buildNetRcFile = config.age.secrets.attic-netrc.path;
        buildMachines = [ ]; # Macs/arm64 builders registered later
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

      # Caddy front (Caddy already enabled by wings.nix; 80/443 already open).
      # Webhooks bypass the auth gate (GitHub posts there, HMAC-verified);
      # everything else on the app domain requires an Authentik session.
      services.caddy.virtualHosts = {
        "${domains.garnixDomain}".extraConfig = ''
          # Never trust client-supplied auth headers; only forward_auth sets them.
          request_header -X-Auth-Request-User
          request_header -X-Auth-Request-Email
          request_header -X-Auth-Request-Groups
          @webhook path /api/events/github/*
          handle @webhook {
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
