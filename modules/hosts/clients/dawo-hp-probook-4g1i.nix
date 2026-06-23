{
  config,
  ...
}:
{
  flake.modules.nixos."hosts/dawo-hp-probook-4g1i" =
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
      networking.hostName = "dawo-hp-probook-4g1i";

      # Desktop choice (exactly one; see desktop-select).
      dawo.desktop.plasma.enable = true;

      # Pilot app set (office workers; they reach a VDI over VPN/F5). LibreOffice
      # by default; dev tools stay off. This HP is a KDE pilot device.
      dawo.apps = {
        office.enable = true; # office.suite defaults to libreoffice
        comms.enable = true;
        creative.enable = true;
        media.enable = true;
      };
    };
}
