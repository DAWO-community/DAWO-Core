{
  flake.modules.nixos.boot-secureboot =
    {
      pkgs,
      lib,
      inputs,
      ...
    }:
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];
      # Add specific packages
      environment.systemPackages = with pkgs; [
        sbctl
        tpm2-tools
        tpm2-tss
      ];

      # Use lanzaboote loader.
      boot.loader.systemd-boot.enable = lib.mkForce false;
      boot.loader.systemd-boot.configurationLimit = 5;
      boot.initrd.systemd.enable = true;
      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };

      # boot.loader.systemd-boot.configurationLimit = 10;
      boot.loader.efi.canTouchEfiVariables = true;

      # Hide the OS choice for bootloaders.
      # It's still possible to open the bootloader list by pressing any key
      # It will just not appear on screen unless a key is pressed
      boot.loader.timeout = 0;
    };
}
