{
  config,
  ...
}:
{
  # Lenovo T495s, GNOME. A standalone target alongside hosts/dawo-t495s (Plasma)
  # so the two desktops can be deployed and tested separately on the same machine:
  #   nixos-rebuild switch --flake .#dawo-t495s         # KDE Plasma
  #   nixos-rebuild switch --flake .#dawo-t495s-gnome   # GNOME
  flake.modules.nixos."hosts/dawo-t495s-gnome" =
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
      networking.hostName = "dawo-t495s-gnome";

      # Desktop choice (exactly one; see desktop-select).
      dawo.desktop.gnome.enable = true;

      # Secure Boot off until sbctl keys are enrolled; flip to true then rebuild.
      dawo.secureboot.enable = false;
    };
}
