{
  flake.modules.nixos.programs-firefox =
    { lib, pkgs, ... }:
    let
      # Spell checking for the ten most spoken languages in Europe (the list in
      # #56). A language pack only translates the interface; the dictionary is a
      # separate thing. Taking them from nixpkgs instead of addons.mozilla.org
      # keeps spell checking working on a device that never reaches Mozilla, and
      # keeps the closure reproducible.
      dictionaryPkgs = with pkgs.hunspellDicts; [
        ru_RU # Russian
        de_DE # German
        fr-any # French
        en_US # English
        en_GB-ise
        it_IT # Italian
        es_ES # Spanish
        pl_PL # Polish
        uk_UA # Ukrainian
        ro_RO # Romanian
        nl_NL # Dutch
      ];

      dictionaries = pkgs.runCommand "dawo-firefox-dictionaries" { } ''
        mkdir -p $out
        for dict in ${lib.concatStringsSep " " (map toString dictionaryPkgs)}; do
          cp -t $out "$dict"/share/hunspell/*.aff "$dict"/share/hunspell/*.dic
        done
        # Firefox reads the file name as the locale code, and fr-any ships as
        # fr-toutesvariantes, which is not one.
        mv $out/fr-toutesvariantes.aff $out/fr_FR.aff
        mv $out/fr-toutesvariantes.dic $out/fr_FR.dic
      '';
    in
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
            "spellchecker.dictionary_path" = "${dictionaries}";
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
