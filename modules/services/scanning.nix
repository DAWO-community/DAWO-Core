{
  # Scanning (SANE). ON by default: the companion to printing - a workplace MFP
  # both prints and scans, and "print but not scan" is exactly the kind of half-
  # covered gap the audit flagged. Driverless network scanning via sane-airscan
  # (eSCL/WSD, the scan equivalent of driverless IPP) plus USB backends, with a
  # DE-agnostic frontend so GNOME hosts get a scanner too (Plasma also ships
  # skanpage). FOSS all the way. Access is via logind uaccess on the local
  # session - no scanner group needed.
  flake.modules.nixos.services-scanning =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dawo.scanning;
    in
    {
      options.dawo.scanning = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "SANE scanning (driverless network + USB) + a scan frontend. On by default.";
        };
      };

      config = lib.mkIf cfg.enable {
        hardware.sane = {
          enable = true;
          extraBackends = [ pkgs.sane-airscan ]; # driverless eSCL/WSD network MFPs
        };
        environment.systemPackages = [ pkgs.simple-scan ];
      };
    };
}
