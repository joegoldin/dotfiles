{
  config,
  pkgs,
  lib,
  ...
}: let
  addons = import ./addons.nix {inherit lib;};
in {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
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
      ExtensionUpdate = false; # Purity Enforcement: Do not update extensions
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
      NoDefaultBookmarks = true; # Do not set default bookmarks
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
      userChrome = ''
        /**
         * Dynamic Horizontal Tabs Toolbar (with animations)
         * sidebar.verticalTabs: false (with native horizontal tabs)
         */
        #main-window #TabsToolbar > .toolbar-items {
          overflow: hidden;
          transition: height 0.3s 0.3s !important;
        }
        /* Default state: Set initial height to enable animation */
        #main-window #TabsToolbar > .toolbar-items { height: 3em !important; }
        #main-window[uidensity="touch"] #TabsToolbar > .toolbar-items { height: 3.35em !important; }
        #main-window[uidensity="compact"] #TabsToolbar > .toolbar-items { height: 2.7em !important; }
        /* Hidden state: Hide native tabs strip */
        #main-window[titlepreface*="sidebery"] #TabsToolbar > .toolbar-items { height: 0 !important; }
        /* Hidden state: Fix z-index of active pinned tabs */
        #main-window[titlepreface*="sidebery"] #tabbrowser-tabs { z-index: 0 !important; }
        /* Hidden state: Hide window buttons in tabs-toolbar */
        #main-window[titlepreface*="sidebery"] #TabsToolbar .titlebar-spacer,
        #main-window[titlepreface*="sidebery"] #TabsToolbar .titlebar-buttonbox-container {
          display: none !important;
        }
        /* [Optional] Uncomment block below to show window buttons in nav-bar (maybe, I didn't test it on non-linux-i3wm env) */
        /* #main-window[titlepreface*="sidebery"] #nav-bar > .titlebar-buttonbox-container,
        #main-window[titlepreface*="sidebery"] #nav-bar > .titlebar-buttonbox-container > .titlebar-buttonbox {
          display: flex !important;
        } */
        /* [Optional] Uncomment one of the line below if you need space near window buttons */
        /* #main-window[titlepreface*="sidebery"] #nav-bar > .titlebar-spacer[type="pre-tabs"] { display: flex !important; } */
        /* #main-window[titlepreface*="sidebery"] #nav-bar > .titlebar-spacer[type="post-tabs"] { display: flex !important; } */

        /* Page action buttons: show dots, reveal on hover */
        #page-action-buttons::after {
          content: "•••";
          position: absolute;
          top: 0.7em;
          font-size: 0.7em;
          opacity: 0.5;
          right: 8px;
          transition: all 50ms ease-in-out;
        }

        #page-action-buttons:hover::after {
          display: none !important;
          width: 0px !important;
          margin-left: 0px !important;
          transition: all 50ms ease-in-out;
        }

        /* URL bar font size */
        #urlbar, #searchbar {
          font-size: 13px !important;
          margin-top: 1px !important;
        }

        /* Nav bar + bookmarks bar: use darker menubar/frame background */
        #nav-bar,
        #PersonalToolbar {
          background-color: var(--lwt-accent-color) !important;
          color: var(--lwt-text-color) !important;
        }
        #nav-bar toolbarbutton image,
        #nav-bar .toolbarbutton-icon,
        #PersonalToolbar toolbarbutton image,
        #PersonalToolbar .toolbarbutton-icon {
          fill: var(--lwt-text-color) !important;
          color: var(--lwt-text-color) !important;
        }

        /* Hide native sidebar header (panel switcher above Sidebery) */
        #sidebar-header {
          display: none !important;
        }
      '';

      settings = {
        # Required for userChrome.css to load
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

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

        "browser.sessionstore.resume_from_crash" = true;

        # See https://librewolf.net/docs/faq/#how-do-i-fully-prevent-autoplay for options
        "media.autoplay.blocking_policy" = 2;

        "signon.management.page.breach-alerts.enabled" = false; # Disable firefox password checking against a breach database

        # Container tabs (used by Sidebery)
        "privacy.userContext.enabled" = true;
        "privacy.userContext.ui.enabled" = true;

        # UI preferences
        "browser.toolbars.bookmarks.visibility" = "always";
        "browser.theme.toolbar-theme" = 0; # Dark toolbar
        "ui.key.menuAccessKeyFocuses" = false; # Disable Alt key focusing menu bar

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
        "privacy.resistFingerprinting" = true;
        "privacy.fingerprintingProtection" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        "browser.safebrowsing.downloads.remote.enabled" = false;
        "network.dns.disablePrefetch" = false;
        "network.predictor.enabled" = false;
        "network.http.speculative-parallel-limit" = 0;
        "browser.places.speculativeConnect.enabled" = false;
        "browser.contentblocking.category" = "strict";
        "extensions.pocket.enabled" = false;
        "browser.search.suggest.enabled.private" = false;
        "browser.privatebrowsing.forceMediaMemoryCache" = true;
        "network.http.referer.XOriginTrimmingPolicy" = 2;
        # Disable CSP reporting: https://bugzilla.mozilla.org/show_bug.cgi?id=1964249
        "security.csp.reporting.enabled" = false;

        ### SECURITY ###
        "pdfjs.enableScripting" = false;
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
    };
  };
}
