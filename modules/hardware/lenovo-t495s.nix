{
  flake.modules.nixos.hardware-lenovo-t495s =
    {
      lib,
      config,
      inputs,
      ...
    }:
    {
      imports = [
        # Upstream device profile (pulls in common-cpu-amd, common-gpu-amd,
        # common-pc-laptop, common-pc-ssd, common-pc-laptop-acpi_call).
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t495
      ];

      hardware.enableAllFirmware = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = false;
      };

      # AMD Ryzen Pro (T495s). initrd modules taken from a real
      # nixos-generate-config on the device; replace on-device with facter.
      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ehci_pci"
        "rtsx_pci_sdmmc"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ ];
      boot.initrd.systemd.enable = true;
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
