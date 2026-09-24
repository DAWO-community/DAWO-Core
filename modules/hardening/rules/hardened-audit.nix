{
  # Kernel audit, at the hardened level rather than the baseline.
  #
  # The rules themselves live in hardening/audit.nix; this entry decides when
  # they apply and how a device proves they loaded. It checks the units rather
  # than `auditctl -l`, because dawo-verify runs without capabilities and
  # listing audit rules needs CAP_AUDIT_CONTROL. audit-rules-nixos stays active
  # only when every rule loaded, so the unit state is the answer.
  flake.dawo.rules."audit-privileged-actions" = {
    title = "Account changes, root commands and kernel modules are audited";
    severity = "hardened";
    tags = [ "audit" ];
    compliance = [ "bio" ];
    why = ''
      journald says what a service printed. It does not say which person
      changed the password file, became root, or loaded a kernel module, and
      that is the question after an incident.

      Off in the baseline because the log costs disk and somebody has to read
      it; until a deployment forwards or collects it, it is evidence on the
      device and nothing more.
    '';
    config =
      { lib, ... }:
      {
        dawo.audit.enable = lib.mkDefault true;
      };
    verify = "systemctl is-active --quiet auditd && systemctl is-active --quiet audit-rules-nixos";
  };
}
