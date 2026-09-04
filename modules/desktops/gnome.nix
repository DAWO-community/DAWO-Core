{
  # GNOME desktop with GDM. Alternative to desktop-plasma; a workplace picks one.
  # Gated behind dawo.desktop.gnome.enable so importing the block does not force
  # GNOME on every host. desktop-select asserts exactly one desktop is enabled.
  flake.modules.nixos.desktop-gnome =
    { config, lib, ... }:
    let
      cfg = config.dawo.desktop.gnome;
    in
    {
      options.dawo.desktop.gnome.enable = lib.mkEnableOption "GNOME desktop with GDM";

      config = lib.mkIf cfg.enable {
        services.displayManager.gdm.enable = true;
        services.desktopManager.gnome.enable = true;

        # Sensible GNOME defaults (plain dconf/gsettings, not locked, so a user
        # can still change them; no extensions, no gnome-tweaks needed). GNOME
        # hides the minimize/maximize buttons by default; restore them, enable
        # tap-to-click and natural scrolling for laptops, and show the date in
        # the top bar. The hardened profile (hardening-gnome) adds its own locked
        # keys; dconf merges both profiles.
        programs.dconf.enable = true;
        programs.dconf.profiles.user.databases = [
          {
            settings = {
              "org/gnome/desktop/wm/preferences".button-layout = "appmenu:minimize,maximize,close";
              "org/gnome/desktop/peripherals/touchpad" = {
                tap-to-click = true;
                natural-scroll = true;
              };
              "org/gnome/desktop/interface".clock-show-date = true;
            };
          }
        ];
      };
    };
}
