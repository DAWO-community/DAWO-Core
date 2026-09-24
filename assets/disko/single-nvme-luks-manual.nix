# Reference layout for partitioning a disk by hand, without nixos-anywhere.
# Run it from the installer, then continue with nixos-install:
#
#   nix run github:nix-community/disko -- --mode destroy,format,mount \
#     ./assets/disko/single-nvme-luks-manual.nix
#
# This is not a NixOS module and it is deliberately outside modules/, which
# import-tree reads as flake-parts modules. The layout matches
# modules/hosts/profiles/disko/single-nvme-luks.nix; change both or neither.
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
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
                name = "crypted-main";
                # if you want to use the key for interactive login be sure
                # there is no trailing newline. For example use
                #   install -m 0600 /dev/null /run/dawo-luks.key
                #   printf '%s' "$passphrase" > /run/dawo-luks.key
                # /run is tmpfs and root-only; /tmp is readable by every user of
                # the installer, and the passphrase is the disk.
                passwordFile = "/run/dawo-luks.key";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Override existing partition
                  # Subvolumes must set a mountpoint in order to be mounted,
                  # unless their parent is mounted
                  subvolumes = {
                    # Subvolume name is different from mountpoint
                    "/rootfs" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/";
                    };
                    # Subvolume name is the same as the mountpoint
                    "/home" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/home";
                    };
                    # Parent is not mounted so the mountpoint must be set
                    "/nix" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/nix";
                    };
                    # Subvolume for the swapfile
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap = {
                        swapfile.size = "16G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
