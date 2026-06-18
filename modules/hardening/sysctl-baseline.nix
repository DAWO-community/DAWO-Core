{
  # System-level hardening (BIO/NCSC, low risk): sysctl, strict sudo, temp-dir
  # mount options, login warning banner. MANDATORY-core tier.
  # Norm: ANSSI R9/R11/R12/R14 + CIS-DIL -> BIO. Origin: securix
  # anssi/kernel-options + filesystems. See architecture.md "Key Design Decisions".
  #
  # The whole baseline is forced (lib.mkForce) - these are mandatory values a
  # host must not silently weaken. No tunables here: it is all floor.
  flake.modules.nixos.hardening-sysctl-baseline =
    { config, lib, ... }:
    let
      cfg = config.dawo.sysctlBaseline;
      # Force every sysctl value so a host override cannot lower the floor.
      forcedSysctl = lib.mapAttrs (_: lib.mkForce) {
        "kernel.kptr_restrict" = 2;
        "kernel.dmesg_restrict" = 1;
        "kernel.kexec_load_disabled" = 1;
        "kernel.unprivileged_bpf_disabled" = 1;
        "net.core.bpf_jit_harden" = 2;
        "kernel.yama.ptrace_scope" = 1;
        "kernel.sysrq" = 0;
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
        "kernel.perf_event_paranoid" = 2;
        "kernel.randomize_va_space" = 2;
        "fs.suid_dumpable" = 0;
        "fs.protected_fifos" = 2;
        "fs.protected_regular" = 2;
      };
    in
    {
      options.dawo.sysctlBaseline.enable = lib.mkEnableOption "kernel/network sysctl baseline, strict sudo, temp-dir + login banner (BIO/NCSC)";

      config = lib.mkIf cfg.enable {
        boot.kernel.sysctl = forcedSysctl;

        security.sudo.execWheelOnly = lib.mkForce true;

        boot.tmp.useTmpfs = true;
        fileSystems."/var/tmp" = {
          device = "/var/tmp";
          fsType = "none";
          options = [
            "bind"
            "nosuid"
            "nodev"
            "noexec"
          ];
        };

        environment.etc."issue".text = ''
          Geautoriseerd gebruik uitsluitend. Activiteit kan worden gelogd/gecontroleerd.
          Authorized use only. Activity may be logged and monitored.
        '';
        environment.etc."issue.net".text = ''
          Geautoriseerd gebruik uitsluitend. Activiteit kan worden gelogd/gecontroleerd.
          Authorized use only. Activity may be logged and monitored.
        '';
      };
    };
}
