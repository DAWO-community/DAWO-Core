{
  config,
  ...
}:
{
  # Starter host, GNOME variant: dawo-generic-intel with the other desktop, so
  # the two can be deployed and tested separately on the same machine:
  #   nixos-rebuild switch --flake .#dawo-generic-intel        # KDE Plasma
  #   nixos-rebuild switch --flake .#dawo-generic-intel-gnome # GNOME
  flake.modules.nixos."hosts/dawo-generic-intel-gnome" =
    { ... }:
    {
      imports = with config.flake.modules.nixos; [
        # Boot - systemd-boot by default; Secure Boot (lanzaboote) is opt-in via
        # dawo.secureboot.enable once sbctl keys are enrolled (see docs/deploy.md).
        boot-loader
        boot-plymouth-bzk

        # Disko - BTRFS single-nvme-luks, the standard DAWO image layout. A fresh
        # install partitions and encrypts the disk (see docs/deploy.md).
        disko-single-nvme-luks

        # Hardware
        hardware-generic-intel

        # Profiles (mandatory hardening included; see profiles.md)
        profiles-dawo-generic

        # Userland
        maid-dawo-generic
      ];
      networking.hostName = "dawo-generic-intel-gnome";

      # Desktop choice (exactly one; see desktop-select).
      dawo.desktop.gnome.enable = true;

      # Pilot app set (office workers; they reach a VDI over VPN/F5). LibreOffice
      # by default (swap to collabora on-site if preferred); dev tools stay off.
      dawo.apps = {
        office.enable = true; # office.suite defaults to libreoffice
        comms.enable = true;
        creative.enable = true;
        media.enable = true;
      };

      # Secure Boot off until sbctl keys are enrolled; flip to true then rebuild.
      dawo.secureboot.enable = false;
    };
}
