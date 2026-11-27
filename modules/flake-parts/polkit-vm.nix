{ config, ... }:
{
  # The two polkit rules from baseline-polkit.nix, asked of polkit itself in a
  # VM. A rule that never matches, or matches more than it should, evaluates
  # fine and reads fine; only polkit deciding for a real session shows which.
  #
  # carol logs in on the console, so the account has the active local session the
  # rules are written for, and pkcheck asks polkit about its login shell:
  # exit 0 is yes, anything else means an administrator (or nothing).
  # Needs KVM.
  perSystem =
    { pkgs, lib, ... }:
    {
      checks.polkit-rules-vm = pkgs.testers.runNixOSTest {
        name = "polkit-rules";
        nodes.machine = {
          imports = map (id: config.flake.dawo.rules.${id}.config { inherit lib pkgs; }) [
            "polkit-firmware-needs-admin"
            "polkit-keeps-removable-media"
          ];
          # The actions under test have to be registered with polkit.
          services.udisks2.enable = true;
          services.fwupd.enable = true;
          users.users.carol = {
            isNormalUser = true;
            password = "carol";
          };
        };
        testScript = ''
          machine.wait_for_unit("multi-user.target")
          machine.wait_until_tty_matches("1", "login: ")
          machine.send_chars("carol\n")
          machine.wait_until_tty_matches("1", "Password: ")
          machine.send_chars("carol\n")
          machine.wait_until_succeeds("pgrep -u carol -x bash")
          machine.succeed("loginctl show-user carol -p State | grep -q active")

          def allowed(action):
              pid = machine.succeed("pgrep -u carol -x bash | head -1").strip()
              rc, out = machine.execute(f"pkcheck --action-id {action} --process {pid}")
              return rc == 0

          fwupd = machine.succeed("pkaction | grep '^org.freedesktop.fwupd'").split()
          assert fwupd, "no fwupd actions registered"
          # What fwupd's own policy allows an active user, split in what the
          # rule takes away and what it leaves.
          changes_firmware = [
              "org.freedesktop.fwupd.update-internal-trusted",
              "org.freedesktop.fwupd.update-hotplug-trusted",
              "org.freedesktop.fwupd.modify-device",
          ]
          stays_open = [
              "org.freedesktop.fwupd.get-remotes",
              "org.freedesktop.fwupd.refresh-remote",
              "org.freedesktop.fwupd.verify",
              "org.freedesktop.fwupd.clear-results",
          ]

          with subtest("changing firmware asks for an administrator"):
              for action in fwupd:
                  if action not in stays_open:
                      assert not allowed(action), f"{action} allowed without an administrator"

          with subtest("refreshing and reading firmware state stays open"):
              for action in stays_open:
                  assert action in fwupd, f"{action} not registered"
                  assert allowed(action), f"{action} needs an administrator"

          with subtest("carol mounts removable media without a password"):
              assert allowed("org.freedesktop.udisks2.filesystem-mount")

          with subtest("system disks and other users' disks still need an administrator"):
              for action in [
                  "org.freedesktop.udisks2.filesystem-mount-system",
                  "org.freedesktop.udisks2.filesystem-mount-other-seat",
                  "org.freedesktop.udisks2.filesystem-mount-other-user",
              ]:
                  assert not allowed(action), f"{action} allowed without an administrator"
        '';
      };
    };
}
