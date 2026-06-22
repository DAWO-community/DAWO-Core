{
  # Hardware/CLI diagnostics for ops/support, opt-in (default off). Keeps the
  # end-user laptop clean while letting a fleet operator enable troubleshooting
  # tools per host (or in an ops overlay).
  flake.modules.nixos.tools-diagnostics =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.tools.diagnostics;
    in
    {
      options.dawo.tools.diagnostics.enable =
        lib.mkEnableOption "hardware/CLI diagnostics for ops/support (htop, lshw, pciutils, dmidecode, ethtool, lm_sensors, usbutils)";

      config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
          htop
          lshw
          pciutils
          dmidecode
          ethtool
          lm_sensors
          usbutils
        ];
      };
    };
}
