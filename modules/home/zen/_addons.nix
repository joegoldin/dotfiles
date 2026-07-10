{
  lib,
  pkgs,
  # The joegoldin/ClearURLs-Addon `patched` branch (see the `clearurls-src`
  # flake input); packaged into an XPI by clearurlsXpi below.
  clearurls-src,
  ...
}:
let
  inherit (lib) mkForce;

  # ClearURLs built from the fork: upstream 1.27.3 + PR #514 (padded-hash fix,
  # unbreaks Claude/OpenAI magic-link logins) + PR #516 (per-site disable).
  # Packaging mirrors upstream's .gitlab-ci.yml `bundle addon` job (a plain
  # zip — no npm, no data/ submodule). The version is bumped to 1.27.3.1 so
  # Firefox upgrades over the installed AMO 1.27.3 and a future upstream
  # 1.27.4 release upgrades over us. The XPI is unsigned, which our Zen build
  # accepts (requireSigning = false) because default.nix turns off
  # xpinstall.signatures.required in the profile.
  clearurlsXpi = pkgs.stdenvNoCC.mkDerivation {
    pname = "clearurls-patched";
    version = "1.27.3.1";
    src = clearurls-src;
    nativeBuildInputs = with pkgs; [
      zip
      jq
    ];
    buildPhase = ''
      jq '.version = "1.27.3.1"' manifest.json > manifest.patched.json
      mv manifest.patched.json manifest.json
      zip -q -r -FS ClearURLs.xpi \
        clearurls.js browser-polyfill.js manifest.json \
        img external_js html core_js css fonts _locales
    '';
    installPhase = ''
      mkdir -p $out
      cp ClearURLs.xpi $out/
    '';
  };

  # Force-installed extension from AMO.
  #
  # Update policy: extensions are PINNED by default (updates_disabled = true);
  # we only auto-update a small, trusted security/privacy set. `extra` overrides
  # the defaults, e.g. { updates_disabled = false; private_browsing = true; }.
  extension = shortId: uuid: extra: {
    name = uuid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "force_installed";
      updates_disabled = true;
    }
    // extra;
  };

  # Trusted security/privacy extensions: keep auto-updates ON (so blocklists and
  # vulnerability fixes land) AND enable them in private/incognito windows.
  trusted = {
    updates_disabled = false;
    private_browsing = true;
  };

in
{
  ExtensionSettings =
    with builtins;
    listToAttrs [
      # Default block rule
      {
        name = "*";
        value = {
          installation_mode = "blocked";
          blocked_install_message = "BLOCKED!";
        };
      }
      (extension "libredirect" "7esoorv3@alefvanoon.anonaddy.me" trusted)
      (extension "terms-of-service-didnt-read" "jid0-3GUEt1r69sQNSrca5p8kx9Ezc3U@jetpack" { })
      (extension "refined-github-" "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" { })
      # ClearURLs: the self-built XPI above instead of AMO — upstream 1.27.3
      # corrupts `=`-padded hash fragments and breaks Claude/OpenAI magic-link
      # logins. Updates stay DISABLED (unlike the usual `trusted` policy) so
      # AMO can't clobber the patched build; revert to
      # `(extension "clearurls" ... trusted)` once upstream releases a version
      # > 1.27.3 with #514 merged.
      {
        name = "{74145f27-f039-47ce-a470-a662b129930a}";
        value = {
          install_url = "file://${clearurlsXpi}/ClearURLs.xpi";
          installation_mode = "force_installed";
          updates_disabled = true;
          private_browsing = true;
        };
      }
      (extension "sponsorblock" "sponsorBlocker@ajay.app" trusted)
      (extension "ublock-origin" "uBlock0@raymondhill.net" trusted)
      (extension "kagi-search-for-firefox" "search@kagi.com" trusted)
      (extension "enhancer-for-youtube" "enhancerforyoutube@maximerf.addons.mozilla.org" { })
      (extension "1password-x-password-manager" "{d634138d-c276-4fc8-924b-40a0ea21d284}" trusted)
      (extension "w2g" "{6ea0a676-b3ef-48aa-b23d-24c8876945fb}" { })
      (extension "mal-sync" "{c84d89d9-a826-4015-957b-affebd9eb603}" { })
      (extension "return-youtube-dislikes" "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" { })
      (extension "tampermonkey" "firefox@tampermonkey.net" trusted)
      (extension "privacy-badger17" "jid1-MnnxcxisBPnSXQ@jetpack" trusted)
      (extension "old-reddit-redirect" "{9063c2e9-e07c-4c2c-9646-cfe7ca8d0498}" { })
      (extension "reddit-enhancement-suite" "jid1-xUfzOsOFlzSOXg@jetpack" { })
      (extension "web-clipper-obsidian" "clipper@obsidian.md" { })
      (extension "tab-session-manager" "Tab-Session-Manager@sienori" { })
      (extension "augmented-steam" "{1be309c5-3e4f-4b99-927d-bb500eb4fa88}" { })
      (extension "soundfixer" "soundfixer@unrelenting.technology" { })
      (extension "improve-crunchyroll" "{2b6c25c8-0c7e-4692-957f-c4ae6af0c34b}" { })
      (extension "crunchy-comments-uwu" "uwuwuwuwuwuwuwuwuwu@wuwuwuwuwuwuwu" { })
      (extension "extension-copycat" "{b38ae201-dd94-40f3-aa1d-04e68c8b9df3}" { })
      (extension "external-application" "{65b77238-bb05-470a-a445-ec0efe1d66c4}" { })
      (extension "modern-for-hacker-news" "{b9edf38a-e293-4606-a088-e63cd4e56d2d}" { })
      (extension "single-file" "{531906d3-e22f-4a6c-a102-8057b88a1a63}" { })
      (extension "byob-bring-your-own-binge" "byob@byob.video" trusted)
    ];
  # To add additional extensions, find it on addons.mozilla.org, find
  # the short ID in the url (like https://addons.mozilla.org/en-US/firefox/addon/!SHORT_ID!/)
  # Then, download the XPI by filling it in to the install_url template, unzip it,
  # run `jq .browser_specific_settings.gecko.id manifest.json` or
  # `jq .applications.gecko.id manifest.json` to get the UUID
  #
  # The 3rd argument controls update/private-browsing policy:
  #   {}        → pinned (no auto-update), not in private windows  [default]
  #   trusted   → auto-update + enabled in private windows
  #   autoUpdate → auto-update only

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
