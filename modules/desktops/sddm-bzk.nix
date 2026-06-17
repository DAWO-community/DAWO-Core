{ ... }:
{
  flake.modules.nixos.desktop-sddm-bzk =
    { lib, pkgs, ... }:
    let
      # Define the custom background package with the correct relative path
      background-package = pkgs.stdenvNoCC.mkDerivation {
        name = "background-image";
        src = ../../artwork/wallpapers/DAWO-achtergrond.png; # Place wallpaper.jpg in the same directory as this config file
        dontUnpack = true;
        installPhase = ''
          cp $src $out
        '';
      };
    in
    {

      services.displayManager = {
        autoLogin.enable = false;
        defaultSession = lib.mkDefault "plasma";
        sddm = {
          enable = true;
          theme = "breeze";
          extraPackages = [ pkgs.kdePackages.plasma-keyboard ];
          settings = {
            General.InputMethod = "plasma-keyboard";
            Wayland = {
              CompositorCommand = "kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1 --inputmethod plasma-keyboard";
            };
            Theme = {
              # Enable avatars for the users displayed in SDDM.
              EnableAvatars = true;
              # set the threshold for the number of users.
              # Avatars are not shown if this threshold is exceeded.
              DisableAvatarsThreshold = 10;
            };
            Users = {
              # See https://kanidm.github.io/kanidm/master/accounts/posix_accounts_and_groups.html#gid-number-generation
              MinimumUid = 1000;
              MaximumUid = 2147483647;
              # SDDM won't display disabled users, nor ID's over 65000,
              # but one can hope for future options.
              RememberLastSession = true;
              RememberLastUser = true;
            };
          };
        };
      };

      environment.systemPackages = [
        (pkgs.writeTextDir "share/sddm/themes/breeze/theme.conf.user" ''
          [General]
          background = "${background-package}"
        '')
      ];
    };
}
