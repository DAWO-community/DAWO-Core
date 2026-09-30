{
  flake.modules.nixos.disko-single-nvme-luks =
    {
      config,
      inputs,
      lib,
      ...
    }:
    let
      cfg = config.dawo.diskEncryption;
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      options.dawo.diskEncryption.passwordFile = lib.mkOption {
        type = lib.types.str;
        default = "/tmp/secret.key";
        description = ''
          Path, ON THE TARGET, of the file disko reads the LUKS passphrase
          from during the install. The imaging step puts it there with
          nixos-anywhere --disk-encryption-keys <this path> <local file>;
          the local file is a 0600 tmpfile the operator pastes or pipes the
          passphrase into, never a shell argument (#112).

          Deliberately a string, not a path literal: a Nix path would copy the
          passphrase into /nix/store, where it is world readable. There is an
          assertion for that. No trailing newline in the file
          (`printf %s`, not echo) or the passphrase carries one.
        '';
      };

      config = {
        assertions = [
          {
            assertion = cfg.passwordFile != "";
            message = "dawo.diskEncryption.passwordFile must be set; disko needs a source for the LUKS passphrase.";
          }
          {
            assertion = !(lib.hasPrefix builtins.storeDir cfg.passwordFile);
            message = ''
              dawo.diskEncryption.passwordFile points into the Nix store,
              which is world readable, so the LUKS passphrase would be
              published to every user of the device and to every build. Give
              it a runtime path on the target instead - nixos-anywhere's
              --disk-encryption-keys copies a local 0600 file there.
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
                      # Read on the target during the disko phase; see the
                      # dawo.diskEncryption.passwordFile option above.
                      inherit (cfg) passwordFile;
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
