_: {
  # HP ProBook 4 G1i (16 inch Notebook AI PC, Intel Core Ultra 5 225U). Model-
  # specific only; the generic bits (firmware, fwupd, bluetooth, initrd-systemd,
  # platform) come from hardware-dawo-base via the profile. The common-* Intel
  # profiles plus the latest kernel cover the Core Ultra platform.
  flake.modules.nixos.hardware-hp-probook-4g1i =
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

      # Ambient-light sensor + Thunderbolt.
      environment.systemPackages = [ pkgs.iio-sensor-proxy ];
      hardware.sensor.iio.enable = true;
      services.hardware.bolt.enable = true;

      hardware.enableAllFirmware = true;

      # Storage/boot devices for this model.
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
      boot.kernelModules = [ "kvm-intel" ];
      boot.kernelPackages = pkgs.linuxPackages_latest;
    };
}
