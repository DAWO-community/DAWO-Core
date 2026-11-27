{ config, ... }:
{
  # The pilot layout, disko-single-nvme-luks, applied for real to an empty
  # disk in a VM, the way nixos-anywhere applies it at install time: the
  # passphrase is written to dawo.disk.luks.passwordFile first, then disko's
  # script partitions, encrypts and mounts. Evaluation shows which path the
  # layout reads; only running disko shows that a passphrase written there
  # the way the module documents ends up as the key of the disk.
  #
  # The disk is /dev/vdb instead of /dev/nvme0n1 and the swapfile is small,
  # so the test does not write 16 GB. Needs KVM.
  perSystem =
    { pkgs, lib, ... }:
    {
      checks.disko-luks-vm = pkgs.testers.runNixOSTest {
        name = "disko-luks";
        nodes.machine = {
          imports = [ config.flake.modules.nixos.disko-single-nvme-luks ];
          # Only the disko script is wanted, not the layout's file systems
          # for the test VM itself.
          disko.enableConfig = false;
          disko.devices.disk.main = {
            device = lib.mkForce "/dev/vdb";
            content.partitions.luks.content.content.subvolumes."/swap".swap.swapfile.size = lib.mkForce "64M";
          };
          virtualisation.emptyDiskImages = [ 4096 ];
          environment.systemPackages = [ pkgs.cryptsetup ];
        };
        testScript =
          { nodes, ... }:
          let
            inherit (nodes.machine.dawo.disk.luks) passwordFile;
            disko = nodes.machine.system.build.diskoScript;
            luks = "/dev/disk/by-partlabel/disk-main-luks";
          in
          ''
            machine.wait_for_unit("multi-user.target")

            with subtest("the layout reads its key from /run"):
                assert "${passwordFile}" == "/run/dawo-luks.key"

            with subtest("disko fails when the key is not where the layout reads it"):
                machine.fail("${disko} >&2")

            with subtest("disko encrypts the disk with the key written as documented"):
                machine.succeed(
                    "install -m 0600 /dev/null ${passwordFile}",
                    "printf '%s' 'correct horse battery staple' > ${passwordFile}",
                    "${disko} >&2",
                )
                machine.succeed("printf '%s' 'correct horse battery staple' | cryptsetup open --test-passphrase ${luks}")
                machine.fail("printf '%s' 'wrong passphrase' | cryptsetup open --test-passphrase ${luks}")
                for mnt in ["/mnt", "/mnt/home", "/mnt/nix", "/mnt/boot"]:
                    machine.succeed(f"findmnt {mnt}")
                machine.succeed("findmnt -no SOURCE /mnt | grep -q /dev/mapper/crypted-main")

            with subtest("the key is root-only on tmpfs and nothing is left in /tmp"):
                assert machine.succeed("stat -c %a ${passwordFile}").strip() == "600"
                assert machine.succeed("findmnt -no FSTYPE -T ${passwordFile}").strip() == "tmpfs"
                machine.fail("test -e /tmp/secret.key")
          '';
      };
    };
}
