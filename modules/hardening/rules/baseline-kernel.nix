{
  # Kernel and filesystem floor, as rules. Configuration still lives in
  # hardening/sysctl-baseline.nix; these are the checks that say whether the
  # values a build promised are the values a running kernel reports.
  #
  # Grouped by what the values are for rather than one rule per sysctl: a
  # deployment turns off "pointer and log exposure" as a decision, not
  # kptr_restrict as a number.
  flake.dawo.rules = {
    "kernel-hide-addresses" = {
      title = "Kernel addresses and logs are not readable by users";
      severity = "baseline";
      tags = [ "kernel" ];
      compliance = [ "bio" ];
      why = ''
        Kernel pointers and the ring buffer are how a local exploit finds out
        where to aim. Hiding them costs a user nothing.
      '';
      config = _: { };
      verify = ''
        [ "$(sysctl -n kernel.kptr_restrict)" = "2" ] \
          && [ "$(sysctl -n kernel.dmesg_restrict)" = "1" ]
      '';
    };

    "kernel-no-kexec" = {
      title = "The running kernel cannot be replaced without a reboot";
      severity = "baseline";
      tags = [ "kernel" ];
      compliance = [ "bio" ];
      why = ''
        kexec loads a new kernel from a running one, which is a way past the
        boot chain Secure Boot is supposed to close.
      '';
      config = _: { };
      verify = ''[ "$(sysctl -n kernel.kexec_load_disabled)" = "1" ]'';
    };

    "kernel-restrict-ptrace" = {
      title = "One user process cannot attach to another";
      severity = "baseline";
      tags = [ "kernel" ];
      compliance = [ "bio" ];
      why = ''
        Unrestricted ptrace lets anything a user runs read the memory of
        everything else they run, including the password manager.
      '';
      config = _: { };
      verify = ''[ "$(sysctl -n kernel.yama.ptrace_scope)" -ge 1 ]'';
    };

    "kernel-aslr-full" = {
      title = "Address space layout is fully randomised";
      severity = "baseline";
      tags = [ "kernel" ];
      compliance = [ "bio" "ncsc" ];
      why = ''
        The cheapest mitigation there is, and the one most exploit chains have
        to work around.
      '';
      config = _: { };
      verify = ''[ "$(sysctl -n kernel.randomize_va_space)" = "2" ]'';
    };
  };
}
