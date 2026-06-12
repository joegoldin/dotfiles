{ inputs, ... }:
let
  dotfiles-secrets = inputs.dotfiles-secrets;
in
{
  den.aspects.zen.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      addons = import ./_addons.nix { inherit lib; };

      # Private container routing (Work container + Containerise site rules) lives in
      # the secrets submodule so the work domains stay out of the public dotfiles.
      containerCfg = import "${dotfiles-secrets}/zen/containers.nix";

      # containers.json definitions (name → id/color/icon). Spaces bind to these
      # containers in-profile, so we keep managing the container set even though the
      # Containerise extension is gone.
      containerDefs = lib.mapAttrs (_: c: {
        inherit (c) id color icon;
      }) containerCfg.containers;

      # Zen Space Routing rules, seeded declaratively via the
      # zen.space-routing.managed-routes pref (read by ZenSpaceRoutingManager).
      # Each former Containerise `{ host, container }` rule becomes a route that
      # sends the host to the Space named after that container; because every Space
      # carries its own default container, this preserves the old cookie-jar
      # isolation. Routes target a Space by NAME, which survives Zen's random
      # per-profile Space ids.
      #
      # `matchType = "regex"` — the host string IS the regex pattern, matched
      # against the full URL (see containers.nix for the syntax).
      #
      # "No Container" rules have no container to target. We route them to the
      # Default Space, which itself carries no container (spaces.nix: container =
      # null), so the old "force out of any container" behaviour is preserved while
      # landing in a concrete Space rather than wherever you happened to be.
      # List order is preserved, so earlier exceptions still win.
      spaceRoutes = map (
        r:
        {
          reference = r.host;
          matchType = "regex";
        }
        // (
          if r.container == "No Container" then
            { openInSpace = "Default"; }
          else
            { openInSpace = r.container; }
        )
      ) containerCfg.rules;

      inherit (pkgs.stdenv.hostPlatform) isDarwin;
    in
    {
      programs.firefox = {
        enable = true;
        # Zen Browser (Firefox fork), built from source from the joegoldin fork
        # (incl. the tree-style-tabs feature, PR #6) via buildMozillaMach — see the
        # `zen-src` flake input. We wrap the *unwrapped* package with nixpkgs' own
        # wrapFirefox so that home-manager's `package.override { extraPolicies }`
        # (mkFirefoxModule.nix) actually threads our policies into policies.json.
        package =
          pkgs.wrapFirefox inputs.zen-src.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
            { };
        # Zen's real profile root: ~/.zen on Linux, ~/Library/Application Support/zen
        # on macOS (source: surfer.json appId="zen" + MOZ_LEGACY_PROFILES=1). Not
        # ~/.mozilla/firefox. profiles.Default lands in <configPath>/Default/ on
        # Linux but <configPath>/Profiles/Default/ on macOS (home-manager's
        # mkFirefoxModule nests profiles under Profiles/ on darwin).
        configPath = if isDarwin then "Library/Application Support/zen" else ".zen";
        # Refer to https://mozilla.github.io/policy-templates or `about:policies#documentation` in firefox
        policies = {
          AppAutoUpdate = false; # Disable automatic application update
          BackgroundAppUpdate = false; # Disable automatic application update in the background, when the application is not running.
          BlockAboutAddons = false;
          BlockAboutConfig = false;
          BlockAboutProfiles = true;
          BlockAboutSupport = true;
          CaptivePortal = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableBuiltinPDFViewer = true; # Considered a security liability
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          DisableFirefoxStudies = true;
          DisableFirefoxAccounts = true; # Disable Firefox Sync
          DisableFirefoxScreenshots = false;
          DisableForgetButton = false; # Thing that can wipe history for X time, handled differently
          DisableMasterPasswordCreation = true; # To be determined how to handle master password
          DisableProfileImport = true; # Purity enforcement: Only allow nix-defined profiles
          DisableProfileRefresh = true; # Disable the Refresh Firefox button on about:support and support.mozilla.org
          DisableSetDesktopBackground = true; # Remove the "Set As Desktop Background…" menuitem when right clicking on an image, because Nix is the only thing that can manage the backgroud
          DisableSystemAddonUpdate = true; # Do not allow addon updates
          DisplayMenuBar = "default-off"; # Whether to show the menu bar
          DisablePocket = true;
          DisableTelemetry = true;
          NetworkPrediction = false;
          SSLVersionMin = "tls1.2";
          PostQuantumKeyAgreementEnabled = true;
          DisableFormHistory = true;
          DisablePasswordReveal = true;
          DontCheckDefaultBrowser = true;
          HardwareAcceleration = true;
          OfferToSaveLogins = false; # Managed by 1pass instead
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
            # Exceptions = ["https://example.com"]
          };
          EncryptedMediaExtensions = {
            Enabled = true;
            Locked = true;
          };
          # Allow updates globally, then pin individual extensions via each entry's
          # `updates_disabled` (see addons.nix): trusted security addons (uBlock,
          # Privacy Badger, 1Password, ClearURLs, …) auto-update; everything else is
          # pinned. Selective control isn't possible with a global hard-off.
          ExtensionUpdate = true;
          # Can be used to restrict domains per extension:
          # "restricted_domains": [
          # 	"TEST_BLOCKED_DOMAIN"
          # ]
          inherit (addons) ExtensionSettings;
          "3rdparty" = addons."3rdparty";

          FirefoxHome = {
            Search = true;
            TopSites = true;
            SponsoredTopSites = false;
            Highlights = true;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
            Locked = true;
          };
          FirefoxSuggest = {
            WebSuggestions = false;
            SponsoredSuggestions = false;
            ImproveSuggest = false;
            Locked = true;
          };
          Handlers = {
            mimeTypes."application/pdf".action = "saveToDisk";
          };
          extensions = {
            # pdf = {
            # 	action = "useHelperApp";
            # 	ask = true;
            # 	handlers = [
            # 		{
            # 			name = "GNOME Document Viewer";
            # 			path = "${pkgs.evince}/bin/evince";
            # 		}
            # 	];
            # };
          };
          # mkForce: home-manager's firefox module also defines this (false) at
          # normal priority since the 2026-06 bump, which otherwise conflicts.
          NoDefaultBookmarks = lib.mkForce true; # Do not set default bookmarks
          PasswordManagerEnabled = false; # Managed by 1pass
          PDFjs = {
            Enabled = false;
            EnablePermissions = false;
          };
          # Permissions = {
          # 	Camera = {
          # 		Allow = [https =//example.org,https =//example.org =1234];
          # 		Block = [https =//example.edu];
          # 		BlockNewRequests = true;
          # 		Locked = true
          # 	};
          # 	Microphone = {
          # 		Allow = [https =//example.org];
          # 		Block = [https =//example.edu];
          # 		BlockNewRequests = true;
          # 		Locked = true
          # 	};
          # 	Location = {
          # 		Allow = [https =//example.org];
          # 		Block = [https =//example.edu];
          # 		BlockNewRequests = true;
          # 		Locked = true
          # 	};
          # 	Notifications = {
          # 		Allow = [https =//example.org];
          # 		Block = [https =//example.edu];
          # 		BlockNewRequests = true;
          # 		Locked = true
          # 	};
          # 	Autoplay = {
          # 		Allow = [https =//example.org];
          # 		Block = [https =//example.edu];
          # 		Default = allow-audio-video | block-audio | block-audio-video;
          # 		Locked = true
          # 	};
          # };
          PictureInPicture = {
            Enabled = true;
            Locked = true;
          };
          PromptForDownloadLocation = true;
          Proxy = {
            Mode = "autoConfig"; # none | system | manual | autoDetect | autoConfig;
            Locked = true;
            # HTTPProxy = hostname;
            # UseHTTPProxyForAllProtocols = true;
            # SSLProxy = hostname;
            # FTPProxy = hostname;
            # SOCKSProxy = "127.0.0.1:9050"; # Tor
            # SOCKSVersion = 5; # 4 | 5
            #Passthrough = <local>;
            AutoConfigURL = "file://${config.home.homeDirectory}/.config/proxy.pac";
            # AutoLogin = true;
            UseProxyForDNS = true;
          };
          SanitizeOnShutdown = {
            Cache = true;
            Cookies = false;
            Downloads = false;
            FormData = true;
            History = false;
            Sessions = false;
            SiteSettings = false;
            OfflineApps = false;
            Locked = true;
          };
          SearchBar = "combined";
          SearchEngines = {
            PreventInstalls = true;
            Add = [
              {
                Name = "Kagi";
                URLTemplate = "https://kagi.com/search?q={searchTerms}";
                Method = "GET";
                IconURL = "https://help.kagi.com/assets/kagi-logo.Bh8O11VU.png";
                Description = "Kagi Search";
              }
            ];
            Remove = [
              "Amazon.com"
              "Bing"
              "eBay"
              "Ecosia"
              "Google"
              "Perplexity"
              "Wikipedia"
            ];
            Default = "Kagi";
          };
          SearchSuggestEnabled = false;
          ShowHomeButton = true;
          # SSLVersionMax = tls1 | tls1.1 | tls1.2 | tls1.3;
          # SSLVersionMin = tls1 | tls1.1 | tls1.2 | tls1.3;
          # SupportMenu = {
          # 	Title = Support Menu;
          # 	URL = http =//example.com/support;
          # 	AccessKey = S
          # };
          StartDownloadsInTempDirectory = true;
          UserMessaging = {
            ExtensionRecommendations = false;
            FeatureRecommendations = false;
            Locked = true;
            MoreFromMozilla = false;
            SkipOnboarding = true;
            UrlbarInterventions = false;
            WhatsNew = false;
            FirefoxLabs = true;
          };
          UseSystemPrintDialog = true;
          # WebsiteFilter = {
          # 	Block = [<all_urls>];
          # 	Exceptions = [http =//example.org/*]
          # };
        };

        profiles.Default = {
          settings = {
            # Auto-enable force-installed extensions in a fresh profile, so the
            # declarative add-ons activate without manual approval after migration.
            "extensions.autoDisableScopes" = 0;

            # Disable middle-click paste from PRIMARY selection. Firefox has its
            # own pref independent of GTK's gtk-enable-primary-paste.
            "middlemouse.paste" = false;

            # Startup with previous session
            "browser.startup.page" = 3;

            # Disable letterboxing
            "privacy.resistFingerprinting.letterboxing" = false;

            # WebGL
            "webgl.disabled" = false;

            "browser.preferences.defaultPerformanceSettings.enabled" = true;
            "layers.acceleration.disabled" = false;

            # Disable Firefox AI features
            "browser.ml.enable" = false;
            "browser.ml.chat.enabled" = false;
            "browser.ml.chat.page.footerBadge" = false;
            "browser.ml.chat.page.menuBadge" = false;
            "browser.ml.chat.shortcuts" = false;
            "browser.ml.chat.shortcuts.custom" = false;
            "browser.ml.chat.sidebar" = false;
            "browser.ml.checkForMemory" = false;
            "browser.ml.linkPreview.enabled" = false;
            "browser.ml.linkPreview.shift" = false;

            "browser.sessionstore.resume_from_crash" = true;

            # See https://librewolf.net/docs/faq/#how-do-i-fully-prevent-autoplay for options
            "media.autoplay.blocking_policy" = 2;

            "signon.management.page.breach-alerts.enabled" = false; # Disable firefox password checking against a breach database

            # Container tabs (used by Sidebery)
            "privacy.userContext.enabled" = true;
            "privacy.userContext.ui.enabled" = true;

            # UI preferences
            "browser.ctrlTab.sortByRecentlyUsed" = true;
            "browser.toolbars.bookmarks.visibility" = "always";
            "sidebar.visibility" = "hide-sidebar";
            "browser.theme.toolbar-theme" = 0; # Dark toolbar
            "ui.key.menuAccessKeyFocuses" = false; # Disable Alt key focusing menu bar

            # Zen-specific UI settings (enforced declaratively).
            "zen.view.use-single-toolbar" = false; # Separate toolbar layout
            "zen.view.compact.enable-at-startup" = false; # Don't start in compact mode
            "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url" = true; # Pinned tabs reopen at pinned URL
            "zen.site-data-panel.show-callout" = false; # Suppress site-data panel callout

            # Space Routing rules (replaces the Containerise extension). Built from
            # the secret host→container rules in spaceRoutes above; routes work
            # domains to the Space named after each container. Requires the
            # zen.space-routing.managed-routes support from the Zen fork.
            "zen.space-routing.managed-routes" = builtins.toJSON spaceRoutes;

            # Declaratively defined Spaces (Default + Work), seeded via the
            # zen.space-routing.managed-spaces support in the Zen fork
            # (ZenManagedSpaces). Created if missing, synced if present, never
            # deleted, read-only in the UI. Container labels resolve against the
            # declarative containers.json above.
            "zen.space-routing.managed-spaces" = builtins.toJSON (import "${dotfiles-secrets}/zen/spaces.nix");

            "media.videocontrols.picture-in-picture.enabled" = true;
            "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
            "media.videocontrols.picture-in-picture.video-toggle.first-seen-secs" = 1746510487;
            "media.videocontrols.picture-in-picture.video-toggle.has-used" = true;
            "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;

            ### DEBLOAT ###
            "browser.discovery.enabled" = false;
            "app.shield.optoutstudies.enabled" = false;
            "browser.topsites.contile.enabled" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            "browser.urlbar.trending.featureGate" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.system.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

            ### PRIVACY ###
            "privacy.resistFingerprinting" = false;
            "privacy.fingerprintingProtection" = true;
            "privacy.fingerprintingProtection.overrides" = "+AllTargets,-JSDateTimeUTC";
            "privacy.globalprivacycontrol.enabled" = true;
            "privacy.donottrackheader.enabled" = true;
            "browser.safebrowsing.downloads.remote.enabled" = false;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "network.dns.disablePrefetch" = true;
            "network.predictor.enabled" = false;
            "network.http.speculative-parallel-limit" = 0;
            "browser.places.speculativeConnect.enabled" = false;
            "browser.contentblocking.category" = "strict";
            "extensions.pocket.enabled" = false;
            "browser.search.suggest.enabled.private" = false;
            "browser.privatebrowsing.forceMediaMemoryCache" = true;
            "network.http.referer.XOriginTrimmingPolicy" = 2;
            "network.http.referer.disallowCrossSiteRelaxingDefault.top_navigation" = true;
            "network.prefetch-next" = false;
            # Disable CSP reporting: https://bugzilla.mozilla.org/show_bug.cgi?id=1964249
            "security.csp.reporting.enabled" = false;

            ### SECURITY ###
            "pdfjs.enableScripting" = false;
            "pdfjs.enabledCache.state" = false;
            "signon.formlessCapture.enabled" = false;
            "dom.disable_window_move_resize" = true;
            # Disable remote debugging: https://gitlab.torproject.org/tpo/applications/tor-browser/-/issues/16222
            "devtools.debugger.remote-enabled" = false;

            ### SSL ###
            "security.ssl.require_safe_negotiation" = true;
            # Disable TLS1.3 0-RTT: https://github.com/tlswg/tls13-spec/issues/1001
            "security.tls.enable_0rtt_data" = 2;
            # Strict public key pinning
            "security.cert_pinning.enforcement_level" = 2;
            # CRLite for revoked certificate detection
            "security.pki.crlite_mode" = 2;
            # Treat unsafe negotiation as broken: https://wiki.mozilla.org/Security:Renegotiation
            "security.ssl.treat_unsafe_negotiation_as_broken" = true;
            # More info on insecure connection warnings (test: https://badssl.com)
            "browser.xul.error_pages.expert_bad_cert" = true;
          };

          # Declarative container definitions (containers.json). Spaces bind to
          # these containers in-profile; force so home-manager owns the file.
          containers = containerDefs;
          containersForce = true;

          # Bookmarks bar + menu, persisted declaratively from secrets/zen/bookmarks.nix
          # (generated by scripts/zen-bookmarks-to-nix.py). force is required by the
          # firefox module whenever settings are non-empty. In-browser bookmark edits
          # are overwritten on rebuild — re-run the extractor to refresh the snapshot.
          bookmarks = {
            force = true;
            settings = import "${dotfiles-secrets}/zen/bookmarks.nix";
          };
        };
      };

      # ── 1Password desktop-app integration ───────────────────────────────────
      # https://docs.zen-browser.app/guides/1password
      # Two pieces make the extension ⇄ desktop-app connection (biometric
      # unlock, shared lock state) work:
      #
      # 1. Trusting the Zen binary, handled per platform:
      #    - Linux (NixOS): modules/system/_sys/1password-browsers.nix writes
      #      /etc/1password/custom_allowed_browsers (root-owned) with the zen
      #      process names. Imported by the joe-desktop and office-pc hosts.
      #    - macOS: 1Password requires the browser bundle to carry a REAL code
      #      signature (ad-hoc and unsigned are both rejected, verified
      #      empirically). The nix store is immutable and builds can't reach the
      #      keychain, so the zenSignedApp activation below maintains a signed
      #      copy at ~/Applications/Zen.app: copy out of the store, patch the
      #      wrapper to exec the local binary (so the *running process* carries
      #      the signature), codesign with the Apple Development identity, and
      #      re-do all of that automatically whenever the Zen store path changes.
      #      One-time: 1Password → Settings → Browser → "Add Browser" →
      #      ~/Applications/Zen.app. Launch Zen from that path (dock pin points
      #      there); the Home Manager Apps copy stays unsigned.
      #
      # 2. The native-messaging manifest (com.1password.1password.json), which
      #    needs no config: gecko hardcodes the user native-messaging base dir
      #    to ~/.mozilla (Linux) / ~/Library/Application Support/Mozilla (macOS)
      #    for ALL forks regardless of branding (XREUserNativeManifests in
      #    nsXREDirProvider — Zen's libxul carries the stock literals), and
      #    that's exactly where the 1Password app maintains its manifest. The
      #    home-manager firefox module keeps the Linux dir alive via a .keep
      #    file. Note this base dir is unrelated to Zen's ~/.zen profile root.

      # Signed Zen.app copy for 1Password (see the comment block above).
      home.activation = lib.optionalAttrs isDarwin {
        zenSignedApp = lib.hm.dag.entryAfter [ "writeBoundary" "trampolineApps" ] ''
          zenSrcLink="$HOME/Applications/Home Manager Apps/Zen.app"
          zenDst="$HOME/Applications/Zen.app"
          zenMarker="$HOME/Applications/.zen-signed-store-path"
          zenIdentity="Apple Development: Joseph Goldin (W65UYY2D42)"
          if [ -L "$zenSrcLink" ]; then
            zenStore=$(/usr/bin/readlink "$zenSrcLink")
            if [ ! -d "$zenDst" ] || [ ! -e "$zenMarker" ] || [ "$(/bin/cat "$zenMarker")" != "$zenStore" ]; then
              if /usr/bin/security find-identity -v -p codesigning | /usr/bin/grep -qF "$zenIdentity"; then
                verboseEcho "zen: re-signing $zenDst from $zenStore"
                run /bin/rm -rf "$zenDst"
                run /bin/cp -RL "$zenStore" "$zenDst"
                run /bin/chmod -R u+w "$zenDst"
                # Exec the local signed binary, not the unsigned store one — the
                # running process must carry the signature for 1Password.
                run /usr/bin/sed -i "" 's|exec "/nix/store/[^"]*/\.zen-old"|exec "$(/usr/bin/dirname "$0")/.zen-old"|' \
                  "$zenDst/Contents/MacOS/zen"
                run /usr/bin/codesign --force --deep --sign "$zenIdentity" "$zenDst"
                run --quiet /bin/sh -c "printf '%s' '$zenStore' > '$zenMarker'"
              else
                echo "zen: codesign identity '$zenIdentity' not in keychain; skipping signed copy" >&2
              fi
            fi
            # The Zen trampoline would launch the unsigned store copy — drop it in
            # favor of the signed app (Spotlight indexes ~/Applications/Zen.app
            # directly, and the dock pin points there too).
            run /bin/rm -rf "$HOME/Applications/Home Manager Trampolines/Zen.app"
          fi
        '';
      };
    };
}
