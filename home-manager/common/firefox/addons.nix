{ lib, ... }:

let
  inherit (lib) mkForce;
in {
  # Can be used to restrict domains per extension:
    # "restricted_domains": [
    # 	"TEST_BLOCKED_DOMAIN"
    # ]
  ExtensionSettings = with builtins;
    let extension = shortId: uuid: {
      name = uuid;
      value = {
        install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
        installation_mode = "force_installed";
      };
    };
    in listToAttrs ([
      # Default block rule
      {
        name = "*";
        value = {
          installation_mode = "blocked";
          blocked_install_message = "BLOCKED!";
        };
      }
      (extension "libredirect" "7esoorv3@alefvanoon.anonaddy.me")
      (extension "terms-of-service-didnt-read" "jid0-3GUEt1r69sQNSrca5p8kx9Ezc3U@jetpack")
      (extension "refined-github" "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}")
      (extension "clearurls" "{74145f27-f039-47ce-a470-a662b129930a}")
      (extension "sponsorblock" "sponsorBlocker@ajay.app")
      (extension "ublock-origin" "uBlock0@raymondhill.net")
      (extension "kagi-search-for-firefox" "search@kagi.com")
      (extension "enhancer-for-youtube" "enhancerforyoutube@maximerf.addons.mozilla.org")
      (extension "1password-x-password-manager" "{d634138d-c276-4fc8-924b-40a0ea21d284}")
      (extension "w2g" "{6ea0a676-b3ef-48aa-b23d-24c8876945fb}")
    ]);
    # To add additional extensions, find it on addons.mozilla.org, find
    # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
    # Then, download the XPI by filling it in to the install_url template, unzip it,
    # run `jq .browser_specific_settings.gecko.id manifest.json` or
    # `jq .applications.gecko.id manifest.json` to get the UUID

  "3rdparty".Extensions = {
    # https://github.com/gorhill/uBlock/blob/master/platform/common/managed_storage.json
    "uBlock0@raymondhill.net".adminSettings = {
      userSettings = rec {
        uiTheme = "dark";
        uiAccentCustom = true;
        uiAccentCustom0 = "#8300ff";
        cloudStorageEnabled = mkForce false; # Security liability?
        importedLists = [
          "https://filters.adtidy.org/extension/ublock/filters/3.txt"
          "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
        ];
        externalLists = lib.concatStringsSep "\n" importedLists;
      };
      selectedFilterLists = [
        "adguard-generic"
        "adguard-annoyance"
        "adguard-social"
        "adguard-spyware-url"
        "easylist"
        "easyprivacy"
        "fanboy-cookiemonster"
        "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
        "plowe-0"
        "ublock-annoyances"
        "ublock-abuse"
        "ublock-badware"
        "ublock-cookies-easylist"
        "ublock-filters"
        "ublock-privacy"
        "ublock-quick-fixes"
        "ublock-unbreak"
        "urlhaus-1"
      ];
    };
  };
} 