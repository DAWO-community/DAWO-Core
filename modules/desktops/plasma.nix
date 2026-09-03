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
      options.dawo.desktop.plasma.unlockWalletAtLogin = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Unlock the KDE wallet with the login password, at the display manager.

          Without this the wallet asks for a password of its own the first time
          something wants a stored credential, which is the prompt people report
          as "why does it ask again". NixOS wires kwallet into the `login` stack
          by itself, but `login` is the tty; SDDM is where anyone actually
          arrives at a desktop.

          It only works when the wallet is named kdewallet and its password
          equals the login password. A device whose wallet was created with a
          different one keeps asking until that wallet is reset.
        '';
      };
      options.dawo.desktop.plasma.kdeconnect = {
        enable = lib.mkEnableOption ''
          KDE Connect. Off by default: it opens TCP and UDP 1714-1764 on every
          interface, and once a phone is paired it carries clipboard contents,
          files, notifications and remote input. That is a reasonable trade on
          a home machine and a decision somebody has to make for a device that
          roams onto networks we do not run
        '';
      };
      options.dawo.desktop.plasma.socialClient = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Ship the Mastodon client (Tokodon). A deployment that does not want a social client sets this false.";
      };

      config = lib.mkIf cfg.enable {
        # Enable the KDE Plasma Desktop Environment.
        services.desktopManager.plasma6.enable = true;

        security.pam.services.sddm.kwallet.enable = cfg.unlockWalletAtLogin;

        programs.kdeconnect.enable = cfg.kdeconnect.enable;

        # BlueZ access for KDE Connect over Bluetooth. `own` is deliberately
        # absent: it would let any user in the group claim the org.bluez name
        # on the system bus and answer as the Bluetooth daemon. Talking to
        # BlueZ needs send_destination and the interfaces below, nothing more.
        services.dbus.packages = lib.mkIf cfg.kdeconnect.enable [
        (pkgs.writeTextFile {
          name = "kdeconnect-bluetooth.conf";
          destination = "/share/dbus-1/system.d/kdeconnect-bluetooth.conf";
          text = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
            <policy group="users">
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
