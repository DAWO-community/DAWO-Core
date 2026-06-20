{
  # auditd (BIO detection). DEFERRED - a no-op on nixpkgs 26.05, so it lives in
  # the opt-in tier (not the forced core) and warns when enabled, rather than
  # faking coverage. Norm: ANSSI R33 + BIO (non-repudiation). Origin: securix.
  #
  # auditctl 4.1.2-unstable + the NixOS audit module reject line 2 of the
  # generated rules file ('error in line 2', status 255), even with a single
  # rule. Module/version bug, not our rules - enabling real rules breaks every
  # `nixos-rebuild switch`. journald + chrony cover the log/time base meanwhile.
  #
  # When the bug is gone, replace the warning with the real ruleset and promote
  # this back into the mandatory core:
  #   security.auditd.enable = true;
  #   security.audit.enable = true;
  #   security.audit.rules = [ "-a exit,always -F arch=b64 -S execve -k exec" ];
  flake.modules.nixos.hardening-audit =
    { config, lib, ... }:
    let
      cfg = config.dawo.audit;
    in
    {
      options.dawo.audit.enable = lib.mkEnableOption "auditd kernel audit (BIO) - deferred, a no-op on nixpkgs 26.05 (module bug)";

      # No silent no-op: enabling it is honest about doing nothing yet.
      config = lib.mkIf cfg.enable {
        warnings = [
          "dawo.audit.enable is set, but auditd is deferred (no-op) on nixpkgs 26.05 due to an auditctl module bug. No audit rules are active; journald covers the interim log base. Track the upstream fix before relying on it."
        ];
      };
    };
}
