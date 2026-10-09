{ inputs, ... }:
{
  flake.modules.nixos.hardware-qemu =
    { modulesPath, ... }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.common-pc-laptop
        (modulesPath + "/virtualisation/qemu-vm.nix")
      ];

      virtualisation = {
        memorySize = 4096;
        cores = 3;
        qemu.guestAgent.enable = true;
      };
    };
}
