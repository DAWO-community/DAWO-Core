{
  # KDE Plasma 6 desktop with SDDM. Alternative to desktop-gnome; a workplace picks
  # one. Gated behind dawo.desktop.plasma.enable so importing the block does not
  # force Plasma on every host. desktop-sddm-bzk pairs its display manager to this
  # flag; desktop-select asserts exactly one desktop is enabled.
  flake.modules.nixos.desktop-plasma =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.dawo.desktop.plasma;
    in
    {
      options.dawo.desktop.plasma.enable = lib.mkEnableOption "KDE Plasma 6 desktop with SDDM";
      options.dawo.desktop.plasma.socialClient = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Ship the Mastodon client (Tokodon). A deployment that does not want a social client sets this false.";
      };

      config = lib.mkIf cfg.enable {
        # Enable the KDE Plasma Desktop Environment.
        services.desktopManager.plasma6.enable = true;

        programs.kdeconnect.enable = true;
        services.dbus.packages = lib.mkIf config.programs.kdeconnect.enable [
        (pkgs.writeTextFile {
          name = "kdeconnect-bluetooth.conf";
          destination = "/share/dbus-1/system.d/kdeconnect-bluetooth.conf";
          text = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
            <policy group="users">
              <allow own="org.bluez"/>
              <allow send_destination="org.bluez"/>
              <allow send_interface="org.bluez.Agent1"/>
              <allow send_interface="org.bluez.MediaEndpoint1"/>
              <allow send_interface="org.bluez.MediaPlayer1"/>
              <allow send_interface="org.bluez.Profile1"/>
              <allow send_interface="org.bluez.GattCharacteristic1"/>
              <allow send_interface="org.bluez.GattDescriptor1"/>
              <allow send_interface="org.bluez.LEAdvertisement1"/>
              <allow send_interface="org.freedesktop.DBus.ObjectManager"/>
              <allow send_interface="org.freedesktop.DBus.Properties"/>
            </policy>
          '';
        })
      ];

      environment.systemPackages = with pkgs; [
        (lib.hiPrio papirus-icon-theme)
        darkly
        digikam
        kdePackages.filelight
        kdePackages.isoimagewriter
        kdePackages.kasts
        kdePackages.kcalc
        kdePackages.kio
        kdePackages.kio-extras
        kdePackages.kio-gdrive
        kdePackages.krdc
        kdePackages.krfb
        kdePackages.krohnkite
        kdePackages.kscreenlocker
        kdePackages.kwidgetsaddons
        kdePackages.partitionmanager
        kdePackages.plasma-keyboard
        kdePackages.qtmultimedia
        kdePackages.qtwebsockets
        kdePackages.skanpage
        kdePackages.yakuake
        kdiskmark
        klassy
        kid3-kde
      ]
      ++ lib.optional cfg.socialClient pkgs.kdePackages.tokodon;
      };
    };
}
