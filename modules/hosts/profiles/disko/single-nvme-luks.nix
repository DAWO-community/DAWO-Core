{
  # Single NVMe, LUKS, btrfs subvolumes. The layout the pilot devices use.
  #
  # The install-time passphrase is a runtime path, never a Nix path literal: a
  # path literal is copied into /nix/store, which is world readable, so the disk
  # key would ship to every user of the device. There is an assertion for that,
  # the same one the comin deploy key has, because the mistake is the same
  # mistake and it is silent both times.
  flake.modules.nixos.disko-single-nvme-luks =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      cfg = config.dawo.disk;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      options.dawo.disk.luks.passwordFile = lib.mkOption {
        type = lib.types.str;
        default = "/run/dawo-luks.key";
        description = ''
          Where disko reads the LUKS passphrase during installation. A runtime
          path on the installer, not a file in this repository and not a Nix
          path literal.

          The default is on tmpfs and readable by root only. The previous value
          was /tmp/secret.key, which every user of the installer could read.
        '';
      };

      config = {
        assertions = [
          {
            assertion = !(lib.hasPrefix builtins.storeDir cfg.luks.passwordFile);
            message = ''
              dawo.disk.luks.passwordFile points into the Nix store, which is
              world readable, so the disk passphrase would be published to every
              user of the device. Give it a runtime path on the installer
              instead.
            '';
          }
        ];
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
                      # Read once, at install time, by disko. It has to be a
                      # string rather than a path literal, and it has to be
                      # somewhere the whole machine cannot read: /run is tmpfs and
                      # root-only, /tmp is not.
                      #
                      # Write it without a trailing newline, or the passphrase
                      # will not match what a person types at the prompt:
                      #   install -m 0600 /dev/null /run/dawo-luks.key
                      #   printf '%s' "$passphrase" > /run/dawo-luks.key
                      passwordFile = cfg.luks.passwordFile;
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
      };
    };
}
