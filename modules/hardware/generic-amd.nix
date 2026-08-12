{
  # A starting point for an AMD laptop whose exact model has no profile yet.
  # The Intel counterpart carries the reasoning; see generic-intel.nix and
  # hardware.md. This differs only in the CPU and GPU profiles it pulls in.
  flake.modules.nixos.hardware-generic-amd =
    { inputs, lib, ... }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-pc-laptop
        inputs.nixos-hardware.nixosModules.common-pc-ssd
        inputs.nixos-hardware.nixosModules.common-cpu-amd # incl. microcode
        inputs.nixos-hardware.nixosModules.common-gpu-amd
      ];

      hardware.enableAllFirmware = lib.mkDefault true;

      # Only what the common-* profiles do not already bring; see the note in
      # generic-intel.nix.
      boot.initrd.availableKernelModules = [
        "rtsx_pci_sdmmc"
        "sdhci_pci"
        "uas"
        "usb_storage"
      ];
      boot.kernelModules = [ "kvm-amd" ];
    };
}
