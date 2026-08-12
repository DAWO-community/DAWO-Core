{
  # A starting point for an Intel laptop whose exact model has no profile yet.
  #
  # Hardware is a downstream concern - the organisation that buys the machines
  # is the only party that knows which ones they are - so the core does not try
  # to carry a module per model. What it can do is make the first boot on a
  # common machine work, so a downstream has something to deploy on day one
  # instead of a hardware module to write before anything runs at all.
  #
  # This is deliberately not a substitute for a real profile. It knows nothing
  # about a specific machine's quirks: no model firmware workarounds, no
  # ambient-light sensor, no Thunderbolt daemon. See hardware.md for the three
  # ways to get a real one (nixos-hardware profile, common-* composition, or
  # nixos-facter detection at install time).
  flake.modules.nixos.hardware-generic-intel =
    { inputs, lib, ... }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-pc-laptop
        inputs.nixos-hardware.nixosModules.common-pc-ssd
        inputs.nixos-hardware.nixosModules.common-cpu-intel # incl. microcode
        inputs.nixos-hardware.nixosModules.common-gpu-intel
      ];

      # Wifi and graphics firmware on many laptops is unfree but not
      # redistributable-flagged, and a machine whose wifi does not come up
      # cannot be fixed remotely.
      hardware.enableAllFirmware = lib.mkDefault true;

      # Only what the common-* profiles do not already bring. ahci, nvme,
      # sd_mod, usbhid and xhci_pci are in the default set, so listing them
      # again would suggest this module is doing work it is not. These four are
      # the difference: SD-card readers, and USB mass storage, which is how a
      # machine reaches an installer on a stick.
      boot.initrd.availableKernelModules = [
        "rtsx_pci_sdmmc"
        "sdhci_pci"
        "uas"
        "usb_storage"
      ];
      boot.kernelModules = [ "kvm-intel" ];
    };
}
