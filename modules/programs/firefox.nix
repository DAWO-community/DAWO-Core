{
  flake.modules.nixos.programs-firefox =
    { pkgs, ... }:
    {
      programs = {
        firefox = {
          enable = true;
          package = pkgs.firefox;
          languagePacks = [
            "nl"
            "en-US"
            "en-GB"
          ];
          preferences = {
            "widget.use-xdg-desktop-portal.file-picker" = 1;
            "browser.ml.enable" = 0;
            "browser.ml.chat.enabled" = 0;
            "browser.ml.chat.page" = 0;
            "browser.ml.linkPreview.enabled" = 0;
            "browser.tabs.groups.smart.enabled" = 0;
            "browser.tabs.groups.smart.userEnabled" = 0;
            "extensions.ml.enabled" = 0;
            "sidebar.notification.badge.aichat" = 0;
            "browser.ml.chat.page.footerBadge" = 0;
            "browser.ml.chat.page.menuBadge" = 0;
            "browser.ml.chat.menu" = 0;
          };

          # ---- POLICIES ----
          # Check about:policies#documentation for options.
          policies = {
            DisableTelemetry = true;
            DisableFirefoxStudies = true;
            EnableTrackingProtection = {
              Value = true;
              Locked = true;
              Cryptomining = true;
              Fingerprinting = true;
            };
            DisablePocket = true;
            DisableFirefoxAccounts = false;
            DisableAccounts = false;
            DisableFirefoxScreenshots = false;
            OverrideFirstRunPage = "";
            OverridePostUpdatePage = "";
            DontCheckDefaultBrowser = true;
            DisplayBookmarksToolbar = "always"; # options: "always", "never", or "newtab"
            DisplayMenuBar = "default-off"; # options: "always", "default-off", "default-on", or "never"
            SearchBar = "unified"; # options: "separate", or "unified"

            # ---- EXTENSIONS ----
            # Check about:support for extension/add-on ID strings.
            # Valid strings for installation_mode are "allowed", "blocked",
            # "force_installed" and "normal_installed".
            ExtensionSettings = {
              "*".installation_mode = "allowed"; # users may install add-ons themselves; set to "blocked" to allow only the ones listed below
              # plasma Integration:
              "plasma-browser-integration@kde.org" = {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/plasma-integration/latest.xpi";
                installation_mode = "force_installed";
              };
            };
          };
        };
      };
    };
}
