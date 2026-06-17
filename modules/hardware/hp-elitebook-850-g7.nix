{
  config,
  ...
}:
{
  flake.modules.nixos.hardware-hp-elitebook-850-g7 =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-pc-laptop
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.nixos-hardware.nixosModules.common-gpu-intel
        inputs.nixos-hardware.nixosModules.common-pc-ssd
      ];

      environment.systemPackages = with pkgs; [
        iio-sensor-proxy
      ];

      hardware.sensor.iio.enable = true;
      hardware.enableAllFirmware = true;

      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
        };
      };

      # Thunderbolt Service
      services.hardware.bolt.enable = true;

      # Ensure boot works with all appropriate storage devices and protocols.
      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "thunderbolt"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [
        "kvm-intel"
        "hp-wmi"
      ];
      boot.initrd.systemd.enable = true;
      boot.initrd.supportedFilesystems = [ ];
      boot.initrd.verbose = false;

      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      boot.kernelPackages = pkgs.linuxPackages_latest;

    };
}
