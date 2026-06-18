{
  # Desktop selector guard. KDE Plasma and GNOME are mutually exclusive: only one
  # desktop block may be evaluated into a host closure, so their packages,
  # services, display managers and theming never collide. A host enables exactly
  # one of dawo.desktop.plasma.enable / dawo.desktop.gnome.enable; this assertion
  # fails the build for zero or both. The options themselves are declared by
  # desktop-plasma and desktop-gnome.
  flake.modules.nixos.desktop-select =
    { config, ... }:
    let
      plasma = config.dawo.desktop.plasma.enable;
      gnome = config.dawo.desktop.gnome.enable;
    in
    {
      assertions = [
        {
          assertion = plasma != gnome;
          message = "Enable exactly one desktop: set dawo.desktop.plasma.enable or dawo.desktop.gnome.enable (not both, not neither).";
        }
      ];
    };
}
