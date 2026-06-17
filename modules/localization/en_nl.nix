{
  flake.modules.nixos.localization-en_nl =
    { pkgs, ... }:
    {
      # Set your time zone.
      time = {
        timeZone = "Europe/Amsterdam";
        hardwareClockInLocalTime = false;
      };

      # Select internationalisation properties.
      i18n = {
        defaultLocale = "en_US.UTF-8";
        extraLocaleSettings = {
          LC_ADDRESS = "nl_NL.UTF-8";
          LC_IDENTIFICATION = "nl_NL.UTF-8";
          LC_MEASUREMENT = "nl_NL.UTF-8";
          LC_MONETARY = "nl_NL.UTF-8";
          LC_NAME = "nl_NL.UTF-8";
          LC_NUMERIC = "nl_NL.UTF-8";
          LC_PAPER = "nl_NL.UTF-8";
          LC_TELEPHONE = "nl_NL.UTF-8";
          LC_TIME = "nl_NL.UTF-8";
        };
        supportedLocales = [
          "en_US.UTF-8/UTF-8"
          "nl_NL.UTF-8/UTF-8"
          "nl_NL/ISO-8859-1"
        ];
      };
      environment.systemPackages = with pkgs; [
        hunspell
        hunspellDicts.en_US
        hunspellDicts.nl_NL
      ];
    };
}
