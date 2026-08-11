{
  flake.modules.nixos.programs-firefox =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.firefox;

      # Spell checking for the ten most spoken languages in Europe (the list in
      # #56). A language pack only translates the interface; the dictionary is a
      # separate thing. Taking them from nixpkgs instead of addons.mozilla.org
      # keeps spell checking working on a device that never reaches Mozilla, and
      # keeps the closure reproducible.
      #
      # Keyed by the locale code Firefox wants, because that is not always what
      # the nixpkgs attribute is called: French comes from `fr-any`, which ships
      # its files as fr-toutesvariantes, and British English from `en_GB-ise`.
      # Naming the target here means the rename is part of the mapping rather
      # than a fixup afterwards that only covers the cases somebody hit.
      dictionarySources = with pkgs.hunspellDicts; {
        de_DE = de_DE; # German
        en_GB = en_GB-ise; # English (British)
        en_US = en_US; # English (American)
        es_ES = es_ES; # Spanish
        fr_FR = fr-any; # French
        it_IT = it_IT; # Italian
        nl_NL = nl_NL; # Dutch
        pl_PL = pl_PL; # Polish
        ro_RO = ro_RO; # Romanian
        ru_RU = ru_RU; # Russian
        uk_UA = uk_UA; # Ukrainian
      };

      # A hunspell package holds exactly one pair. If one ever holds more, the
      # cp below fails on a non-directory target rather than silently picking
      # whichever file the glob happened to expand to first.
      dictionaries = pkgs.runCommand "dawo-firefox-dictionaries" { } ''
        mkdir -p $out
        ${lib.concatMapStringsSep "\n" (locale: ''
          cp "${dictionarySources.${locale}}"/share/hunspell/*.aff "$out/${locale}.aff"
          cp "${dictionarySources.${locale}}"/share/hunspell/*.dic "$out/${locale}.dic"
        '') cfg.dictionaries}
      '';
    in
    {
      options.dawo.firefox.dictionaries = lib.mkOption {
        type = lib.types.listOf (lib.types.enum (lib.attrNames dictionarySources));
        default = lib.attrNames dictionarySources;
        example = [
          "nl_NL"
          "en_GB"
        ];
        description = ''
          Spell check dictionaries installed for Firefox, by locale code.

          The default is all eleven on offer - the ten most spoken languages in
          Europe, with English in both its spellings - which costs about 26 MB
          on every device. A deployment that knows its users only write two
          languages should say so and carry only those.

          The empty list installs none and leaves Firefox without spell
          checking.
        '';
      };

      config = {
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
              # Left unset when no dictionary was asked for, rather than pointed
              # at an empty directory: Firefox then falls back to whatever the
              # user installs themselves instead of being told there is nothing.
            }
            // lib.optionalAttrs (cfg.dictionaries != [ ]) {
              "spellchecker.dictionary_path" = "${dictionaries}";
            }
            // {
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
    };
}
