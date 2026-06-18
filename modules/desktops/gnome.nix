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
      };
    };
}
