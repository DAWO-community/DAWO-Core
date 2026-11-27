{ config, ... }:
{
  # The audit ruleset from hardening/audit.nix, loaded by a real kernel in a
  # VM. The rules evaluate whatever auditctl thinks of them: audit
  # 4.1.2-unstable rejected every rules file NixOS generated, and one path
  # that does not exist yet fails the whole unit. Only booting with them, and
  # finding a user's actions back, shows they work. Needs KVM.
  perSystem =
    { pkgs, ... }:
    {
      checks.audit-vm = pkgs.testers.runNixOSTest {
        name = "audit";
        nodes.machine = {
          imports = [ config.flake.modules.nixos.hardening-audit ];
          dawo.audit.enable = true;
          users.users.alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
          security.sudo.wheelNeedsPassword = false;
        };
        testScript = ''
          machine.wait_for_unit("auditd")
          machine.wait_for_unit("audit-rules-nixos")

          with subtest("every rule is loaded"):
              rules = machine.succeed("auditctl -l")
              n = len([l for l in rules.splitlines() if l.startswith("-")])
              assert n == 9, f"expected 9 rules, got {n}:\n{rules}"

          with subtest("the rules survive a reload, as on every switch"):
              for _ in range(2):
                  machine.succeed("systemctl restart audit-rules-nixos")
                  machine.succeed("systemctl is-active audit-rules-nixos")

          with subtest("a user's sudo, an account change and a module load are found back"):
              # A real login sets the loginuid (pam_loginuid); do the same here.
              machine.succeed("sh -c 'echo 1000 > /proc/self/loginuid; exec runuser -u alice -- sudo -n true'")
              machine.succeed("useradd bob")
              machine.succeed("modprobe dummy && modprobe -r dummy")
              machine.wait_until_succeeds("ausearch -k privileged -ua 1000 | grep -q sudo", timeout=60)
              machine.succeed("ausearch -k identity | grep -q useradd")
              machine.succeed("ausearch -k modules | grep -q modprobe")
        '';
      };
    };
}
