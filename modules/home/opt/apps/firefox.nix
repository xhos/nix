# {
#   inputs,
#   pkgs,
#   ...
# }: {
#   programs.firefox = {
#     enable = true;
#     package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
#       extraPolicies = {
#         CaptivePortal = false;
#         DisableFirefoxStudies = true;
#         DisablePocket = true;
#         DisableTelemetry = true;
#         DisableFirefoxAccounts = false;
#         NoDefaultBookmarks = true;
#         OfferToSaveLogins = false;
#         OfferToSaveLoginsDefault = false;
#         PasswordManagerEnabled = false;
#         FirefoxHome = {
#           Search = true;
#           Pocket = false;
#           Snippets = false;
#           TopSites = false;
#           Highlights = false;
#         };
#         UserMessaging = {
#           ExtensionRecommendations = false;
#           SkipOnboarding = true;
#         };
#       };
#     };
#     profiles = {
#       default = let
#         scifox = pkgs.fetchFromGitHub {
#           owner = "scientiac";
#           repo = "scifox";
#           rev = "618b97dc318e0cd0d2822d7e7302fdd098f9c544";
#           hash = "sha256-F+h33dRs0Q2+9p66uI7QH+yifADkh9Hl48rbVtOzkvk=";
#         };
#       in {
#         id = 0;
#         isDefault = true;
#         # https://github.com/scientiac/scifox/blob/main/sidebery.json
#         # userChrome = builtins.readFile "${scifox}/chrome/userChrome.css";
#         # userContent = builtins.readFile "${scifox}/chrome/userContent.css";
#         # http://kb.mozillazine.org/Category:Preferences
#         settings = {
#           "browser.search.defaultenginename" = "google";
#           "browser.shell.checkDefaultBrowser" = false;
#           "browser.shell.defaultBrowserCheckCount" = 1;
#           "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
#           "browser.newtabpage.activity-stream.improvesearch.handoffToAwesomebar" = false;
#           "browser.aboutConfig.showWarning" = false;
#           "browser.ctrlTab.sortByRecentlyUsed" = false;
#           "widget.use-xdg-desktop-portal.file-picker" = 1;
#           "widget.use-xdg-desktop-portal.mime-handler" = 1;
#           "browser.search.suggest.enabled" = false;
#           "browser.translations.neverTranslateLanguages" = "ru";
#           "browser.search.suggest.enabled.private" = false;
#           "browser.urlbar.suggest.searches" = false;
#           "browser.urlbar.showSearchSuggestionsFirst" = false;
#           "browser.sessionstore.enabled" = true;
#           "browser.sessionstore.resume_from_crash" = true;
#           "browser.sessionstore.resume_session_once" = true;
#           "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
#           "browser.tabs.drawInTitlebar" = true;
#           "svg.context-properties.content.enabled" = true;
#           "general.smoothScroll" = true;
#           "uc.tweak.hide-tabs-bar" = true;
#           "uc.tweak.hide-forward-button" = true;
#           "uc.tweak.rounded-corners" = true;
#           "uc.tweak.floating-tabs" = true;
#           "layout.css.color-mix.enabled" = true;
#           "layout.css.light-dark.enabled" = true;
#           "layout.css.has-selector.enabled" = true;
#           "media.ffmpeg.vaapi.enabled" = false;
#           "media.rdd-vpx.enabled" = true;
#           "browser.tabs.tabmanager.enabled" = false;
#           "full-screen-api.ignore-widgets" = false;
#           "browser.urlbar.suggest.engines" = false;
#           "browser.urlbar.suggest.openpage" = false;
#           "browser.urlbar.suggest.bookmark" = false;
#           "browser.urlbar.suggest.addons" = false;
#           "browser.urlbar.suggest.pocket" = false;
#           "browser.urlbar.suggest.topsites" = false;
#         };
#         extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
#           vimium
#           adaptive-tab-bar-colour
#           don-t-fuck-with-paste
#           ublock-origin
#           i-dont-care-about-cookies
#           clearurls
#           decentraleyes
#           privacy-badger
#           proton-pass
#           proton-vpn
#           darkreader
#           search-by-image
#           steam-database
#           github-file-icons
#           sponsorblock
#           return-youtube-dislikes
#         ];
#         search = {
#           force = true;
#           default = "Google";
#           order = ["Google" "Yandex" "Youtube" "Nix Options" "Nix Packages" "Home Manager"];
#           engines = {
#             "Yandex" = {
#               iconUpdateURL = "https://ya.ru/favicon.ico";
#               updateInterval = 24 * 60 * 60 * 1000;
#               definedAliases = ["@y"];
#               urls = [
#                 {
#                   template = "https://ya.ru/search";
#                   params = [
#                     {
#                       name = "text";
#                       value = "{searchTerms}";
#                     }
#                   ];
#                 }
#               ];
#             };
#             "YouTube" = {
#               iconUpdateURL = "https://youtube.com/favicon.ico";
#               updateInterval = 24 * 60 * 60 * 1000;
#               definedAliases = ["@yt"];
#               urls = [
#                 {
#                   template = "https://www.youtube.com/results";
#                   params = [
#                     {
#                       name = "search_query";
#                       value = "{searchTerms}";
#                     }
#                   ];
#                 }
#               ];
#             };
#             "Nix Packages" = {
#               icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
#               definedAliases = ["@np"];
#               urls = [
#                 {
#                   template = "https://search.nixos.org/packages";
#                   params = [
#                     {
#                       name = "type";
#                       value = "packages";
#                     }
#                     {
#                       name = "query";
#                       value = "{searchTerms}";
#                     }
#                   ];
#                 }
#               ];
#             };
#             "NixOS Options" = {
#               icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
#               definedAliases = ["@no"];
#               urls = [
#                 {
#                   template = "https://search.nixos.org/options";
#                   params = [
#                     {
#                       name = "channel";
#                       value = "unstable";
#                     }
#                     {
#                       name = "query";
#                       value = "{searchTerms}";
#                     }
#                   ];
#                 }
#               ];
#             };
#             "Home Manager" = {
#               icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
#               definedAliases = ["@hm"];
#               url = [
#                 {
#                   template = "https://mipmip.github.io/home-manager-option-search/";
#                   params = [
#                     {
#                       name = "query";
#                       value = "{searchTerms}";
#                     }
#                   ];
#                 }
#               ];
#             };
#           };
#         };
#       };
#       FTWA = {
#         id = 1;
#         userChrome = ''
#           TabsToolbar {
#             visibility: collapse;
#           }
#           :root:not([customizing]) #navigator-toolbox {
#             max-height: 1px;
#             min-height: calc(0px);
#             overflow: hidden;
#           }
#           #navigator-toolbox::after {
#             display: none !important;
#           }
#           #main-window[sizemode="maximized"] #content-deck {
#             padding-top: 8px;
#           }
#         '';
#         settings = {
#           "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
#           "browser.translations.automaticallyPopup" = false;
#         };
#       };
#     };
#   };
# }
{}
