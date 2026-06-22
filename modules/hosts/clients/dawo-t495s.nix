{
  config,
  ...
}:
{
  flake.modules.nixos."hosts/dawo-t495s" =
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
        hardware-lenovo-t495s

        # Profiles
        profiles-dawo-generic

        # Userland
        maid-dawo-generic

        # Mandatory BIO/NCSC hardening (usbguard, ssh, sysctl, chrony, audit) is
        # pulled in automatically by profiles-dawo-generic, which imports
        # profiles-dawo-core and forces those blocks on. To turn on an opt-in
        # block, import profiles-dawo-hardened and flip the one you want, e.g.:
        #   dawo.apparmor.enable = true;
      ];
      networking.hostName = "dawo-t495s";

      # Desktop choice (exactly one; see desktop-select). Flip to gnome.enable to
      # test GNOME on the same host: rebuild swaps the desktop.
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
