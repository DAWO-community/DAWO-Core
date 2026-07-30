{
  # Generic hardware baseline for every DAWO laptop - the bits that were
  # duplicated across the per-model modules. A model module adds only its
  # specifics (a nixos-hardware profile, CPU microcode, model initrd modules);
  # an unknown fleet model can rely on this base + nixos-facter instead of a
  # hand-written module. See hardware.md for the pick/look-up/make convention.
  flake.modules.nixos.hardware-dawo-base =
    { lib, ... }:
    {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

      # Firmware: redistributable blobs + vendor firmware updates (fwupd).
      hardware.enableRedistributableFirmware = lib.mkDefault true;
      services.fwupd.enable = lib.mkDefault true;

      hardware.bluetooth = {
        enable = lib.mkDefault true;
        powerOnBoot = lib.mkDefault false;
      };

      # systemd in initrd (needed for TPM/FIDO2 LUKS unlock later, and the
      # general direction in 26.05).
      boot.initrd.systemd.enable = lib.mkDefault true;

      # NTFS read/write for USB sticks/disks formatted on Windows.
      boot.supportedFilesystems = [ "ntfs" ];

      # zram: compressed RAM swap - better low-memory behaviour than leaning on
      # the disk swapfile alone.
      zramSwap.enable = lib.mkDefault true;
    };
}
