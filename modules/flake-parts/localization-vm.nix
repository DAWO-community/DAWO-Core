{ config, ... }:
{
  # dawo.localization on a running system. Whether a user can switch the
  # desktop to another language comes down to whether glibc has the locale
  # on the device; an option that evaluates says nothing about that. So this
  # boots the default (Dutch, every language offered) and a trimmed English
  # desktop with Dutch formats, and asks glibc and the files on disk.
  # Needs KVM.
  perSystem = _: {
    checks.localization-vm = config.flake.nixosConfigurations.dawo-t495s.pkgs.testers.runNixOSTest {
      name = "localization";
      nodes = {
        dutch = {
          imports = [ config.flake.modules.nixos.localization-languages ];
          dawo.localization.enable = true;
        };
        english = {
          imports = [ config.flake.modules.nixos.localization-languages ];
          dawo.localization = {
            enable = true;
            options = {
              systemLanguage = "en_gb";
              regionalFormats = "nl";
              offer = [ ];
            };
          };
        };
      };
      testScript = ''
        start_all()
        dutch.wait_for_unit("multi-user.target")
        english.wait_for_unit("multi-user.target")

        # 3 September 2026 was a Thursday.
        def weekday(machine, locale):
            return machine.succeed(f"LANG={locale} LC_ALL= LC_TIME= date -u -d 2026-09-03 +%A").strip()

        with subtest("the default is Dutch, with Dutch formats and Amsterdam time"):
            conf = dutch.succeed("cat /etc/locale.conf")
            assert "LANG=nl_NL.UTF-8" in conf, conf
            assert "LC_TIME=nl_NL.UTF-8" in conf, conf
            assert dutch.succeed("readlink -f /etc/localtime").strip().endswith("Europe/Amsterdam")

        with subtest("every offered language is generated, so a user can switch to it"):
            expected = {
                "ru_RU.UTF-8": "четверг",
                "de_DE.UTF-8": "Donnerstag",
                "fr_FR.UTF-8": "jeudi",
                "en_US.UTF-8": "Thursday",
                "en_GB.UTF-8": "Thursday",
                "it_IT.UTF-8": "giovedì",
                "es_ES.UTF-8": "jueves",
                "pl_PL.UTF-8": "czwartek",
                "uk_UA.UTF-8": "четвер",
                "ro_RO.UTF-8": "joi",
                "nl_NL.UTF-8": "donderdag",
            }
            for locale, day in expected.items():
                got = weekday(dutch, locale)
                # Case differs between locales (glibc capitalises Russian).
                assert got.casefold() == day.casefold(), f"{locale}: {got!r}, expected {day!r}"

        with subtest("every offered language has its spell checker"):
            # Spell checkers look a dictionary up by the locale's name.
            for dic in [l.split(".")[0] for l in expected]:
                dutch.succeed(f"test -e /run/current-system/sw/share/hunspell/{dic}.dic")

        with subtest("menus and formats are two settings"):
            conf = english.succeed("cat /etc/locale.conf")
            assert "LANG=en_GB.UTF-8" in conf, conf
            assert "LC_TIME=nl_NL.UTF-8" in conf, conf
            assert "LC_PAPER=nl_NL.UTF-8" in conf, conf

        with subtest("a trimmed offer generates only what it names"):
            assert weekday(english, "en_GB.UTF-8") == "Thursday"
            assert weekday(english, "nl_NL.UTF-8") == "donderdag"
            # glibc falls back to C for a locale that was not generated.
            assert weekday(english, "de_DE.UTF-8") == "Thursday"
            english.fail("test -e /run/current-system/sw/share/hunspell/de_DE.dic")
      '';
    };
  };
}
