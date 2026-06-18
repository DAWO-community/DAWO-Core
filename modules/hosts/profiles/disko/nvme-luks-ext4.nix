{
  # GPT/UEFI: ESP (512M vfat) + LUKS2-container met ext4-root op /dev/nvme0n1.
  # Matcht een bestaande install met luks-naam "cryptroot" (geen btrfs) — bedoeld
  # voor in-place migratie ZONDER wipe: de gegenereerde fileSystems sluiten aan
  # op de al gepartitioneerde schijf. (Verse install = `disko --mode disko`.)
  flake.modules.nixos.disko-nvme-luks-ext4 =
    { inputs, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];
      disko.devices.disk.main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              type = "EF00";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot";
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
}
