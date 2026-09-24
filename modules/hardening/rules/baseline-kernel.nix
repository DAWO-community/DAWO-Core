{ lib, ... }:
let
  # A rule's sysctls, forced, so a host override cannot lower a rule that still
  # reports PASS. A host that wants a different value turns the rule off.
  sysctls =
    values:
    { lib, ... }:
    {
      boot.kernel.sysctl = lib.mapAttrs (_: lib.mkForce) values;
    };

  # The check reads back the same values the rule sets, so the two cannot drift.
  readBack =
    values:
    lib.concatStringsSep " \\\n  && " (
      lib.mapAttrsToList (key: value: ''[ "$(sysctl -n ${key})" = "${toString value}" ]'') values
    );

  rule =
    attrs: values:
    attrs
    // {
      config = sysctls values;
      verify = attrs.verify or (readBack values);
    };
in
{
  # Kernel and filesystem floor, as rules. Each rule sets its own sysctls and
  # reads them back from the running kernel, so turning a rule off takes the
  # values away as well, and the device says whether what a build promised is
  # what the kernel reports.
  #
  # Moved here from hardening/sysctl-baseline.nix. The move was done when the
  # generated sysctl.d file stayed byte for byte the same on every host.
  #
  # Grouped by what the values are for rather than one rule per sysctl: a
  # deployment turns off "pointer and log exposure" as a decision, not
  # kptr_restrict as a number.
  flake.dawo.rules = {
    "kernel-hide-addresses" =
      rule
        {
          title = "Kernel addresses and logs are not readable by users";
          severity = "baseline";
          tags = [ "kernel" ];
          compliance = [ "bio" ];
          why = ''
            Kernel pointers and the ring buffer are how a local exploit finds out
            where to aim. Hiding them costs a user nothing.
          '';
        }
        {
          "kernel.kptr_restrict" = 2;
          "kernel.dmesg_restrict" = 1;
        };

    "kernel-no-kexec" =
      rule
        {
          title = "The running kernel cannot be replaced without a reboot";
          severity = "baseline";
          tags = [ "kernel" ];
          compliance = [ "bio" ];
          why = ''
            kexec loads a new kernel from a running one, which is a way past the
            boot chain Secure Boot is supposed to close.
          '';
        }
        {
          "kernel.kexec_load_disabled" = 1;
        };

    "kernel-restrict-ptrace" =
      rule
        {
          title = "One user process cannot attach to another";
          severity = "baseline";
          tags = [ "kernel" ];
          compliance = [ "bio" ];
          why = ''
            Unrestricted ptrace lets anything a user runs read the memory of
            everything else they run, including the password manager.
          '';
          # At least 1, not exactly: a device that raised it further is stricter,
          # not wrong.
          verify = ''[ "$(sysctl -n kernel.yama.ptrace_scope)" -ge 1 ]'';
        }
        {
          "kernel.yama.ptrace_scope" = 1;
        };

    "kernel-aslr-full" =
      rule
        {
          title = "Address space layout is fully randomised";
          severity = "baseline";
          tags = [ "kernel" ];
          compliance = [
            "bio"
            "ncsc"
          ];
          why = ''
            The cheapest mitigation there is, and the one most exploit chains have
            to work around.
          '';
        }
        {
          "kernel.randomize_va_space" = 2;
        };

    "kernel-restrict-bpf-and-perf" =
      rule
        {
          title = "Users cannot load BPF programs or read kernel performance events";
          severity = "baseline";
          tags = [ "kernel" ];
          compliance = [ "bio" ];
          why = ''
            Unprivileged BPF and perf events are two of the most used ways into
            the kernel from a user account. A workplace user has no use for
            either; a developer who does turns this off for their device.
          '';
        }
        {
          "kernel.unprivileged_bpf_disabled" = 1;
          "net.core.bpf_jit_harden" = 2;
          "kernel.perf_event_paranoid" = 2;
        };

    "kernel-no-sysrq" =
      rule
        {
          title = "The SysRq key combinations are off";
          severity = "baseline";
          tags = [ "kernel" ];
          compliance = [ "bio" ];
          why = ''
            SysRq lets whoever is at the keyboard kill processes or reboot the
            device without logging in, which on a locked screen is a way around
            the lock.
          '';
        }
        {
          "kernel.sysrq" = 0;
        };

    "network-refuse-rerouting" =
      rule
        {
          title = "The network stack ignores redirects, source routes and spoofed sources";
          severity = "baseline";
          tags = [ "network" ];
          compliance = [
            "bio"
            "ncsc"
          ];
          why = ''
            A laptop is not a router. Redirects and source routes let a machine on
            the same network steer this one's traffic, and on hotel or cafe wifi
            that machine is not ours.
          '';
        }
        {
          "net.ipv4.conf.all.rp_filter" = 1;
          "net.ipv4.conf.default.rp_filter" = 1;
          "net.ipv4.tcp_syncookies" = 1;
          "net.ipv4.conf.all.accept_redirects" = 0;
          "net.ipv6.conf.all.accept_redirects" = 0;
          "net.ipv4.conf.all.accept_source_route" = 0;
          "net.ipv4.conf.default.accept_source_route" = 0;
          "net.ipv4.conf.all.send_redirects" = 0;
          "net.ipv4.conf.default.send_redirects" = 0;
          "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        };

    "fs-protect-shared-dirs" =
      rule
        {
          title = "Shared directories are safe from link tricks, and setuid programs leave no core dumps";
          severity = "baseline";
          tags = [ "filesystem" ];
          compliance = [ "bio" ];
          why = ''
            A file planted in /tmp by one user can make a privileged program write
            where the planter wants. The protected_* settings close that, and a
            core dump of a setuid program can hold what it read as root.
          '';
        }
        {
          "fs.suid_dumpable" = 0;
          "fs.protected_fifos" = 2;
          "fs.protected_regular" = 2;
        };
  };
}
