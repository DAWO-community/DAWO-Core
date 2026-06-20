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
      ];

      # Forced on - mandatory on every device, not silently droppable. Only
      # controls that are invisible and cannot lock a user out belong here.
      # usbControl moved to the opt-in tier: blocking USB out of the box breaks
      # the user experience (no stick/dongle), so it is a deliberate opt-in.
      # audit moved to the opt-in tier too: it is a no-op on nixpkgs 26.05
      # (auditctl module bug), so forcing it here only faked coverage.
      dawo.ssh.enable = lib.mkForce true;
      dawo.sysctlBaseline.enable = lib.mkForce true;
      dawo.timesync.enable = lib.mkForce true;
    };
}
