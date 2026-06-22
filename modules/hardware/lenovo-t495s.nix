{
  flake.modules.nixos.hardware-lenovo-t495s =
    { inputs, ... }:
    {
      # Model-specific only. The generic bits (firmware, fwupd, bluetooth,
      # initrd-systemd, platform) come from hardware-dawo-base via the profile.
      imports = [
        # Upstream device profile (pulls in common-cpu-amd, common-gpu-amd,
        # common-pc-laptop, common-pc-ssd, common-pc-laptop-acpi_call - incl. AMD
        # microcode).
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t495
      ];

      # AMD T495s may need unfree firmware (wifi/gpu) beyond redistributable.
      hardware.enableAllFirmware = true;

      # AMD Ryzen Pro (T495s). initrd modules from a real nixos-generate-config
      # on the device; an unknown model uses nixos-facter instead.
      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ehci_pci"
        "rtsx_pci_sdmmc"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-amd" ];
    };
}
