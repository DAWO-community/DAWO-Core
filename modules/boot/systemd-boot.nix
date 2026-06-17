{
  flake.modules.nixos.boot-systemd =
    {
      ...
    }:
    {
      # Use the 'systemd-boot EFI' boot loader.
      boot.loader.systemd-boot.enable = true;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.initrd.systemd.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      # Hide the OS choice for bootloaders.
      # It's still possible to open the bootloader list by pressing any key
      # It will just not appear on screen unless a key is pressed
      boot.loader.timeout = 0;
    };
}
