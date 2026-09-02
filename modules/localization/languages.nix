{
  # System language, regional formats and the set of languages a user can switch
  # the desktop to.
  #
  # Two settings that people conflate and this block keeps apart. The language
  # is what the menus are written in; the regional formats are what a date, a
  # currency and a decimal separator look like. A civil servant in Amsterdam
  # reading an English desktop still wants 3 september 2026 and 1.234,56 - so
  # `systemLanguage` and `regionalFormats` are two options, not one.
  #
  # Changing the desktop language afterwards is a user action, not a rebuild: a
  # locale can only be selected in Plasma or GNOME if it was generated on the
  # device, so the block generates every language in `offer` up front. That
  # costs disk, not maintenance, and the alternative is a helpdesk ticket for a
  # thing the user could have done in a menu.
  flake.modules.nixos.localization-languages =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.localization;

      # The ten most spoken languages in Europe by native speakers, per the
      # list #56 names, plus nothing else: a language belongs here when a
      # deployment is likely to need it, not because the locale exists.
      #
      # `dict` is the hunspell dictionary attribute in nixpkgs. The names are
      # not uniform (fr ships variants by spelling reform rather than by
      # country, en by dialect), which is why this is a table rather than a
      # pattern applied to a locale string.
      catalogue = {
        ru = {
          locale = "ru_RU.UTF-8";
          dict = "ru_RU";
        };
        de = {
          locale = "de_DE.UTF-8";
          dict = "de_DE";
        };
        fr = {
          locale = "fr_FR.UTF-8";
          dict = "fr-moderne";
        };
        en = {
          locale = "en_US.UTF-8";
          dict = "en_US";
        };
        en_gb = {
          locale = "en_GB.UTF-8";
          dict = "en_GB-ise";
        };
        it = {
          locale = "it_IT.UTF-8";
          dict = "it_IT";
        };
        es = {
          locale = "es_ES.UTF-8";
          dict = "es_ES";
        };
        pl = {
          locale = "pl_PL.UTF-8";
          dict = "pl_PL";
        };
        uk = {
          locale = "uk_UA.UTF-8";
          dict = "uk_UA";
        };
        ro = {
          locale = "ro_RO.UTF-8";
          dict = "ro_RO";
        };
        nl = {
          locale = "nl_NL.UTF-8";
          dict = "nl_NL";
        };
      };

      known = lib.attrNames catalogue;
      localeOf = key: catalogue.${key}.locale;
      formats = localeOf cfg.options.regionalFormats;
    in
    {
      options.dawo.localization = {
        enable = lib.mkEnableOption "system language, regional formats and the languages a user can switch to";

        options.systemLanguage = lib.mkOption {
          type = lib.types.enum known;
          default = "nl";
          description = ''
            Language the desktop and system messages are written in. One of
            ${lib.concatStringsSep ", " known}.

            A user can switch to any language in `offer` from the desktop
            settings afterwards; this is what a freshly imaged device starts in.
          '';
        };

        options.regionalFormats = lib.mkOption {
          type = lib.types.enum known;
          default = "nl";
          description = ''
            Country whose conventions are used for dates, times, numbers,
            currency, paper size and addresses, independent of the language.

            Kept separate from `systemLanguage` on purpose: an English-language
            desktop in the Netherlands still writes 3-9-2026 on A4.
          '';
        };

        options.timeZone = lib.mkOption {
          type = lib.types.str;
          default = "Europe/Amsterdam";
          example = "Europe/Brussels";
          description = "IANA time zone. The hardware clock stays on UTC.";
        };

        options.offer = lib.mkOption {
          type = lib.types.listOf (lib.types.enum known);
          default = known;
          example = [
            "nl"
            "en"
          ];
          description = ''
            Languages generated on the device, and therefore selectable by a
            user without a rebuild. Defaults to all of them.

            Trim it where the disk is tight or a deployment wants a shorter menu.
            `systemLanguage` and `regionalFormats` are always generated whether
            they are listed here or not, because a device that cannot generate
            its own locale has no working locale at all.
          '';
        };

        options.spellCheckers = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Install a hunspell dictionary for every offered language, so
            spell checking follows the language the user picked rather than
            only the one the device was imaged in.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        time = {
          timeZone = cfg.options.timeZone;
          hardwareClockInLocalTime = false;
        };

        i18n = {
          defaultLocale = localeOf cfg.options.systemLanguage;

          # Every LC_* that describes a convention rather than a language, so
          # the split promised above actually holds.
          extraLocaleSettings = {
            LC_ADDRESS = formats;
            LC_IDENTIFICATION = formats;
            LC_MEASUREMENT = formats;
            LC_MONETARY = formats;
            LC_NAME = formats;
            LC_NUMERIC = formats;
            LC_PAPER = formats;
            LC_TELEPHONE = formats;
            LC_TIME = formats;
          };

          supportedLocales = lib.unique (
            map (key: "${localeOf key}/UTF-8") (
              cfg.options.offer
              ++ [
                cfg.options.systemLanguage
                cfg.options.regionalFormats
              ]
            )
          );
        };

        environment.systemPackages =
          lib.optionals cfg.options.spellCheckers ([ pkgs.hunspell ] ++ (
            map (key: pkgs.hunspellDicts.${catalogue.${key}.dict}) (
              lib.unique (
                cfg.options.offer
                ++ [
                  cfg.options.systemLanguage
                  cfg.options.regionalFormats
                ]
              )
            )
          ));
      };
    };
}
