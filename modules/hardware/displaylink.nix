{
  # DisplayLink docks. Off by default and enabled per device.
  #
  # Without it a dock drives exactly one external monitor. The extra outputs are
  # DisplayLink's own, and nothing in a stock kernel knows how to talk to them,
  # which is why the second screen stays dark rather than reporting an error.
  #
  # THE DRIVER CANNOT LIVE IN THIS REPOSITORY. It is unfree and
  # non-redistributable, so it may not be published here and it is not in
  # cache.nixos.org either. nixpkgs handles that with requireFile, which makes
  # every device's store a place somebody has to put a file by hand - fine for
  # one laptop, unworkable for a fleet.
  #
  # So the URL is configuration instead. Point dawo.displaylink.driverUrl at an
  # organisation's own mirror, or at the vendor's direct download, and the build
  # fetches it like any other source. What makes that safe is that the hash is
  # pinned, not the URL: the archive is checked against the hash nixpkgs expects
  # for the version it packages, so a mirror that serves something else fails
  # the build instead of shipping it to a fleet.
  flake.modules.nixos.hardware-displaylink =
    {
      config,
      lib,
      options,
      ...
    }:
    let
      cfg = config.dawo.displaylink;
    in
    {
      options.dawo.displaylink = {
        enable = lib.mkEnableOption "DisplayLink dock support (evdi + DisplayLink Manager)";

        driverUrl = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "https://mirror.example.org/displaylink-620.zip";
          description = ''
            Where to fetch the DisplayLink driver archive. Required when this
            block is enabled, because the driver may not be redistributed here.

            An organisation's own mirror is the better answer for a fleet: one
            place to serve it from, no EULA click per device, and it keeps
            working when the vendor moves its download. The vendor's direct link
            works too. A `file://` path is accepted for a one-off machine.

            The URL is not trusted - `driverHash` is. Whatever this points at
            must hash to the value nixpkgs expects, or the build fails.
          '';
        };

        driverHash = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "sha256-JQO7eEz4pdoPkhcn9tIuy5R4KyfsCniuw6eXw/rLaYE=";
          description = ''
            Expected hash of the archive. Null takes the hash nixpkgs itself
            expects for the version it packages, which is the right answer
            almost always: it moves with a nixpkgs bump instead of pinning this
            fleet to whichever release happened to be current when someone wrote
            it down.

            Set it only to hold a specific archive deliberately, and expect to
            revisit it when nixpkgs bumps the package.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.driverUrl != "";
            message = ''
              dawo.displaylink.enable needs dawo.displaylink.driverUrl.

              The DisplayLink driver is non-redistributable, so it is not in this
              repository and not in cache.nixos.org. Point driverUrl at your own
              mirror of the archive, or at the vendor's download. It is checked
              against the hash nixpkgs expects, so a wrong file fails the build
              rather than reaching a device.
            '';
          }
        ];

        # nixpkgs declares dlm.service with an EMPTY wantedBy: nothing starts
        # it. It comes up only through the driver's udev rule, which matches
        # the USB interface (17e9, class ff, protocol 03) on ACTION=="add".
        # That is enough when a dock is hotplugged and usually enough at boot,
        # since udev replays add events - but "usually" is what "one of my two
        # screens" looks like from a user's chair. Wanting it from
        # graphical.target makes it unconditional, and the daemon costs nothing
        # on a device with no dock attached.
        systemd.services.dlm.wantedBy = [ "graphical.target" ];

        # Load evdi in the initrd rather than at boot, so the module is present
        # before anything enumerates displays instead of arriving while the
        # session is already deciding what outputs it has.
        boot.initrd.kernelModules = [ "evdi" ];

        # Everything below configures the X11 half. Both blocks are needed:
        # under Wayland it is evdi and dlm that drive the dock, and under X11
        # those are needed too - the driver and the provider hand-off sit on
        # top of them.
        #
        # Appended to the upstream default rather than replacing it.
        # videoDrivers carries a default (modesetting, fbdev) and a default is
        # replaced by any definition, not merged with it - so writing
        # `[ "displaylink" ]` here would take modesetting away from the internal
        # panel and leave a laptop driving its dock and nothing else. Read the
        # default off the option so this stays correct if nixpkgs changes it.
        services.xserver.videoDrivers = options.services.xserver.videoDrivers.default ++ [ "displaylink" ];

        # Swap requireFile for a normal fetch. Same archive, same hash, but the
        # device can get it by itself. The name is kept from the original so the
        # store path reads the same as it would upstream.
        nixpkgs.overlays = [
          (final: prev: {
            displaylink = prev.displaylink.overrideAttrs (old: {
              src = final.fetchurl {
                inherit (old.src) name;
                url = cfg.driverUrl;
                hash = if cfg.driverHash != null then cfg.driverHash else old.src.outputHash;
              };
            });
          })
        ];
      };
    };
}
