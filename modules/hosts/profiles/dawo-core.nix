{
  config,
  ...
}:
{
  # MANDATORY-core tier aggregate. A workplace imports this to inherit the
  # BIO/NCSC obligations that must hold on every device. The mandatory blocks
  # are forced on with `lib.mkForce`: a consumer can *configure* them through
  # `dawo.<block>.options.*`, but cannot silently drop one. (Suggested defaults
  # inside the blocks use `lib.mkDefault`; only the security-critical enforcement
  # is forced.) Opt-in (hardened-tier) blocks stay default OFF; enable them per
  # workplace via profiles-dawo-hardened.
  flake.modules.nixos.profiles-dawo-core =
    { lib, ... }:
    {
      imports = with config.flake.modules.nixos; [
        hardening-ssh
        hardening-sysctl-baseline
        hardening-timesync
        hardening-audit
      ];

      # Forced on - mandatory on every device, not silently droppable. Only
      # controls that are invisible and cannot lock a user out belong here.
      # usbControl moved to the opt-in tier: blocking USB out of the box breaks
      # the user experience (no stick/dongle), so it is a deliberate opt-in.
      dawo.ssh.enable = lib.mkForce true;
      dawo.sysctlBaseline.enable = lib.mkForce true;
      dawo.timesync.enable = lib.mkForce true;
      # audit is a no-op on 26.05 (see hardening/audit.nix); enabled so the
      # contract is in place, the body fills once the module bug is fixed.
      dawo.audit.enable = lib.mkForce true;
    };
}
