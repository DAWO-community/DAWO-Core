{
  config,
  ...
}:
{
  # HP ProBook 4 G1i, GNOME. The one GNOME unit in the six-laptop pilot (the
  # other five are KDE on the same hardware). Same client recipe as
  # dawo-hp-probook-4g1i, only the desktop differs:
  #   nixos-rebuild switch --flake .#dawo-hp-probook-4g1i         # KDE Plasma
  #   nixos-rebuild switch --flake .#dawo-hp-probook-4g1i-gnome   # GNOME
  flake.modules.nixos."hosts/dawo-hp-probook-4g1i-gnome" =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        # Boot - systemd-boot by default; Secure Boot opt-in via dawo.secureboot.
        boot-loader
        boot-plymouth-bzk

        # Disko
        disko-single-nvme-luks

        # Hardware
        hardware-hp-probook-4g1i

        # Profiles
        profiles-dawo-generic

        # Userland
        maid-dawo-generic
      ];
      networking.hostName = "dawo-hp-probook-4g1i-gnome";

      # Desktop choice (exactly one; see desktop-select).
      dawo.desktop.gnome.enable = true;

      # Pilot app set (office workers; they reach a VDI over VPN/F5). LibreOffice
      # by default; dev tools stay off.
      dawo.apps = {
        office.enable = true; # office.suite defaults to libreoffice
        comms.enable = true;
        creative.enable = true;
        media.enable = true;
      };
    };
}
