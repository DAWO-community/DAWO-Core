{
  config,
  ...
}:
{
  # Starter host: a common Intel laptop whose exact model has no profile yet
  # (hardware-generic-intel). Hardware is downstream's call (#171) - the core
  # ships generic starters so day one is a deployment rather than a hardware
  # module to write first; a fleet that knows its models replaces this import
  # with a real profile in its own overlay (see modules/hardware/hardware.md).
  flake.modules.nixos."hosts/dawo-generic-intel" =
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
      networking.hostName = "dawo-generic-intel";

      # Desktop choice (exactly one; see desktop-select). The -gnome variant
      # pairs GNOME with the same hardware block.
      dawo.desktop.plasma.enable = true;

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
