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
        inputs.nixos-hardware.nixosModules.common-pc-laptop
        inputs.nixos-hardware.nixosModules.common-cpu-amd
        inputs.nixos-hardware.nixosModules.common-gpu-amd
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];

      hardware.enableAllFirmware = true;
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = false;
      };

      # AMD Ryzen Pro (T495s). initrd-modules afgeleid van een echte
      # nixos-generate-config op het toestel; on-device met facter te vervangen.
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
