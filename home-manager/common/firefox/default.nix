{
  config,
  pkgs,
  lib,
  firefox-addons,
  ...
}: let
  inherit (lib) mkForce;
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
      ExtensionSettings = addons.ExtensionSettings;
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
          "Google"
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
        ExtensionRecommendations = false; # Don't recommend extensions while the user is visiting web pages
        FeatureRecommendations = false; # Don't recommend browser features
        Locked = true; # Prevent the user from changing user messaging preferences
        MoreFromMozilla = false; # Don't show the "More from Mozilla" section in Preferences
        SkipOnboarding = true; # Don't show onboarding messages on the new tab page
        UrlbarInterventions = false; # Don't offer suggestions in the URL bar
        WhatsNew = false; # Remove the "What's New" icon and menuitem
      };
      UseSystemPrintDialog = true;
      # WebsiteFilter = {
      # 	Block = [<all_urls>];
      # 	Exceptions = [http =//example.org/*]
      # };
    };

    profiles.Default = {
      settings = {
        # Startup with previous session
        "browser.startup.page" = 3;

        # Enable letterboxing
        "privacy.resistFingerprinting.letterboxing" = true;

        # WebGL
        "webgl.disabled" = false;

        "browser.preferences.defaultPerformanceSettings.enabled" = true;
        "layers.acceleration.disabled" = false;
        "privacy.globalprivacycontrol.enabled" = true;

        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        # "network.trr.mode" = 3;

        # "network.dns.disableIPv6" = false;

        "privacy.donottrackheader.enabled" = true;

        # "privacy.clearOnShutdown.history" = true;
        # "privacy.clearOnShutdown.downloads" = true;
        "browser.sessionstore.resume_from_crash" = true;

        # See https://librewolf.net/docs/faq/#how-do-i-fully-prevent-autoplay for options
        "media.autoplay.blocking_policy" = 2;

        "privacy.resistFingerprinting" = true;

        "signon.management.page.breach-alerts.enabled" = false; # Disable firefox password checking against a breach database

        "media.videocontrols.picture-in-picture.enabled" = true;
        "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled" = true;
        "media.videocontrols.picture-in-picture.video-toggle.first-seen-secs" = 1746510487;
        "media.videocontrols.picture-in-picture.video-toggle.has-used" = true;
        "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;
      };
    };
  };
}
